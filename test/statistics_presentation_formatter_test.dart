import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/statistics/domain/recovery_domain_service.dart';
import 'package:hypertrack/features/statistics/presentation/statistics_formatter.dart';
import 'package:hypertrack/generated/app_localizations_de.dart';
import 'package:hypertrack/generated/app_localizations_en.dart';
import 'package:hypertrack/util/body_nutrition_analytics_utils.dart';

void main() {
  group('StatisticsPresentationFormatter', () {
    test('formats compact numbers with k suffix', () {
      expect(StatisticsPresentationFormatter.compactNumber(999), '999');
      expect(StatisticsPresentationFormatter.compactNumber(1250), '1.3k');
      expect(StatisticsPresentationFormatter.compactNumber(12.5), '12.5');
    });

    test('detects other-category labels robustly', () {
      expect(
        StatisticsPresentationFormatter.isOtherCategoryLabel('other'),
        true,
      );
      expect(
        StatisticsPresentationFormatter.isOtherCategoryLabel('Others'),
        true,
      );
      expect(
        StatisticsPresentationFormatter.isOtherCategoryLabel('  OTHER  '),
        true,
      );
      expect(
        StatisticsPresentationFormatter.isOtherCategoryLabel('Other Data'),
        false,
      );
      expect(StatisticsPresentationFormatter.isOtherCategoryLabel(null), false);
    });

    test('maps recovery overall labels and state labels', () {
      final l10n = AppLocalizationsEn();

      expect(
        StatisticsPresentationFormatter.recoveryOverallLabel(
          l10n,
          RecoveryDomainService.overallMostlyRecovered,
        ),
        l10n.recoveryOverallMostlyRecovered,
      );
      expect(
        StatisticsPresentationFormatter.recoveryStateLabel(
          l10n,
          RecoveryDomainService.stateRecovering,
        ),
        l10n.recoveryStateRecovering,
      );
      expect(
        StatisticsPresentationFormatter.recoveryStateLabel(l10n, 'unexpected'),
        l10n.recoveryStateUnknown,
      );
    });

    test('maps body nutrition insight labels', () {
      final l10n = AppLocalizationsDe();

      expect(
        StatisticsPresentationFormatter.bodyNutritionInsightLabel(
          l10n,
          BodyNutritionInsightType.notEnoughData,
        ),
        l10n.analyticsInsightNotEnoughData,
      );
      expect(
        StatisticsPresentationFormatter.bodyNutritionInsightLabel(
          l10n,
          BodyNutritionInsightType.mixed,
        ),
        l10n.analyticsInsightMixedPattern,
      );
    });

    test('maps body nutrition trend, relationship, and confidence labels', () {
      final l10n = AppLocalizationsEn();

      expect(
        StatisticsPresentationFormatter.bodyNutritionTrendDirectionLabel(
          l10n,
          BodyNutritionTrendDirection.rising,
        ),
        l10n.analyticsTrendRising,
      );
      expect(
        StatisticsPresentationFormatter.bodyNutritionRelationshipLabel(
          l10n,
          BodyNutritionRelationshipType.alignedCutLike,
        ),
        l10n.analyticsRelationshipAlignedCut,
      );
      expect(
        StatisticsPresentationFormatter.bodyNutritionConfidenceLabel(
          l10n,
          BodyNutritionConfidence.moderate,
        ),
        l10n.analyticsModerateConfidenceLabel,
      );
    });

    test('maps muscle guidance label', () {
      final l10n = AppLocalizationsEn();

      expect(
        StatisticsPresentationFormatter.muscleGuidanceLabel(l10n, false, const [
          'Legs',
        ]),
        l10n.analyticsKeepTrackingUnlockInsights,
      );
      expect(
        StatisticsPresentationFormatter.muscleGuidanceLabel(
          l10n,
          true,
          const [],
        ),
        l10n.analyticsGuidanceNoClearWeakPoint,
      );
      expect(
        StatisticsPresentationFormatter.muscleGuidanceLabel(l10n, true, const [
          'Legs',
          'Back',
        ]),
        l10n.analyticsGuidanceLowerEmphasis('Legs, Back'),
      );
    });

    testWidgets('maps recovery colors', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        StatisticsPresentationFormatter.recoveryStateColor(
          context,
          RecoveryDomainService.stateRecovering,
        ),
        Colors.orange,
      );
      expect(
        StatisticsPresentationFormatter.recoveryOverallColor(
          context,
          RecoveryDomainService.overallMostlyRecovered,
        ),
        Colors.green,
      );
    });
  });
}
