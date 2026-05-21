import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_metadata_row.dart';

/// A reusable row that displays kcal and macronutrient values.
///
/// Can switch between a plain text style (using [AppMetadataRow]) and a
/// colorful badge style based on the [useBadges] parameter.
///
/// Colors for the badges are looked up via the [MacroColors] theme extension.
class MacroBadgeRow extends StatelessWidget {
  final int? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? caffeine;
  final int? waterMl;

  /// Whether to render as colorful badges or plain metadata text.
  final bool useBadges;

  /// Optional text style for the plain text mode.
  final TextStyle? style;

  const MacroBadgeRow({
    super.key,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.sugar,
    this.caffeine,
    this.waterMl,
    this.useBadges = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!useBadges) {
      return _buildPlainRow(context);
    }
    return _buildBadgeRow(context);
  }

  Widget _buildPlainRow(BuildContext context) {
    final items = <String>[];
    if (kcal != null) items.add('$kcal kcal');
    if (protein != null && protein! > 0) items.add('${protein!.toStringAsFixed(0)}g P');
    if (carbs != null && carbs! > 0) items.add('${carbs!.toStringAsFixed(0)}g C');
    if (fat != null && fat! > 0) items.add('${fat!.toStringAsFixed(0)}g F');
    if (sugar != null && sugar! > 0) items.add('${sugar!.toStringAsFixed(0)}g Sugar');
    if (caffeine != null && caffeine! > 0) items.add('${caffeine!.toStringAsFixed(0)}mg Caffeine');
    if (waterMl != null && waterMl! > 0) items.add('${waterMl}ml');

    return AppMetadataRow(
      items: items,
      style: style,
    );
  }

  Widget _buildBadgeRow(BuildContext context) {
    final theme = Theme.of(context);
    final macroColors = theme.extension<MacroColors>();
    
    // Fallback colors if extension is missing (should not happen if registered)
    final kcalColor = macroColors?.calories ?? Colors.orange;
    final proteinColor = macroColors?.protein ?? Colors.red;
    final carbsColor = macroColors?.carbs ?? Colors.green;
    final fatColor = macroColors?.fat ?? Colors.deepOrange;
    final sugarColor = macroColors?.sugar ?? Colors.pink;
    final caffeineColor = macroColors?.caffeine ?? Colors.brown;
    final waterColor = macroColors?.water ?? Colors.blue;

    final badges = <Widget>[];

    if (kcal != null) {
      badges.add(_badge('$kcal', 'kcal', kcalColor, theme));
    }
    if (protein != null && protein! > 0) {
      badges.add(_badge('P ${protein!.toStringAsFixed(0)}', 'g', proteinColor, theme));
    }
    if (carbs != null && carbs! > 0) {
      badges.add(_badge('C ${carbs!.toStringAsFixed(0)}', 'g', carbsColor, theme));
    }
    if (fat != null && fat! > 0) {
      badges.add(_badge('F ${fat!.toStringAsFixed(0)}', 'g', fatColor, theme));
    }
    if (sugar != null && sugar! > 0) {
      badges.add(_badge('S ${sugar!.toStringAsFixed(0)}', 'g', sugarColor, theme));
    }
    if (caffeine != null && caffeine! > 0) {
      badges.add(_badge(caffeine!.toStringAsFixed(0), 'mg', caffeineColor, theme));
    }
    if (waterMl != null && waterMl! > 0) {
      badges.add(_badge(waterMl.toString(), 'ml', waterColor, theme));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _badge(String value, String unit, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value$unit',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
