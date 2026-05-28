// lib/features/exercise_catalog/domain/body_slug_mapper.dart

import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../statistics/domain/recovery_domain_service.dart';

/// Maps raw muscle name strings (as stored in the wger exercise database)
/// to one or more [BodyPartSlug] values suitable for the [BodyHighlighter]
/// widget.
///
/// Resolution order:
///   1. Direct [BodyPartSlug.fromString] lookup (handles most single-muscle
///      names like "biceps", "quads", "hamstrings", "chest", "triceps", …).
///   2. Canonical major-group lookup via [RecoveryDomainService.majorMuscleGroupFor],
///      which normalises aliases like "traps", "lats", "pecs" first.
///   3. Manual canonical-group → slug(s) mapping for aggregate groups
///      (e.g. "back" → trapezius + upperBack, "shoulders" → front + rear delts).
///
/// For the "shoulders" canonical group the split is anatomically correct:
///   * [BodyPartSlug.frontDeltoids] — appears on the **front** view only.
///   * [BodyPartSlug.backDeltoids] — appears on the **back** view only.
/// Callers that render a single view should filter by [BodySide].
class BodySlugMapper {
  const BodySlugMapper._();

  /// Resolved slugs for each canonical major-group key.
  ///
  /// "shoulders" deliberately returns both front and back deltoid slugs so
  /// each view highlights the anatomically correct region.
  static const Map<String, List<BodyPartSlug>> _canonicalToSlugs = {
    'chest': [BodyPartSlug.chest],
    'back': [BodyPartSlug.trapezius, BodyPartSlug.upperBack],
    'shoulders': [BodyPartSlug.frontDeltoids, BodyPartSlug.backDeltoids],
    'biceps': [
      BodyPartSlug.biceps,
      BodyPartSlug.biceps_long,
      BodyPartSlug.biceps_short,
    ],
    'triceps': [BodyPartSlug.triceps],
    'quads': [BodyPartSlug.quadriceps],
    'hamstrings': [BodyPartSlug.hamstring],
    'glutes': [BodyPartSlug.gluteal],
    'calves': [BodyPartSlug.calves, BodyPartSlug.tibialis],
    'lower back': [BodyPartSlug.lowerBack],
    'abs': [BodyPartSlug.abs, BodyPartSlug.obliques],
    'adductors': [BodyPartSlug.adductor],
    'forearms': [BodyPartSlug.forearm],
  };

  /// Which side of the body each slug is visible on.
  ///
  /// Used by [forSide] to filter slugs to only those relevant for a given
  /// [BodySide] when rendering a single view.
  ///
  /// Slugs NOT listed here are shown on BOTH views (front and back).
  static const Map<BodyPartSlug, BodySide> _slugSide = {
    // Front-only slugs
    BodyPartSlug.chest: BodySide.front,
    BodyPartSlug.abs: BodySide.front,
    BodyPartSlug.obliques: BodySide.front,
    BodyPartSlug.frontDeltoids: BodySide.front,
    BodyPartSlug.biceps: BodySide.front,
    BodyPartSlug.biceps_long: BodySide.front,
    BodyPartSlug.biceps_short: BodySide.front,
    BodyPartSlug.quadriceps: BodySide.front,
    BodyPartSlug.abductors: BodySide.front,
    BodyPartSlug.tibialis: BodySide.front,
    BodyPartSlug.adductor: BodySide.front,
    BodyPartSlug.neck: BodySide.front,
    // Back-only slugs
    BodyPartSlug.upperBack: BodySide.back,
    BodyPartSlug.lowerBack: BodySide.back,
    BodyPartSlug.backDeltoids: BodySide.back,
    BodyPartSlug.triceps: BodySide.back,
    BodyPartSlug.gluteal: BodySide.back,
    BodyPartSlug.hamstring: BodySide.back,
    // Visible on both sides — no entry means shown on both
    // BodyPartSlug.trapezius → both (front collar and back neck area)
    // BodyPartSlug.calves → both (gastrocnemius has a rear silhouette entry)
    // BodyPartSlug.forearm → both (SVG has paths on front + back views)
  };

  /// Maps a single raw muscle name (e.g. `"chest"`, `"front delts"`,
  /// `"latissimus"`) to the corresponding [BodyPartSlug] values.
  ///
  /// Returns an empty list when no mapping can be determined.
  static List<BodyPartSlug> fromRawName(String rawName) {
    final cleaned = rawName.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

    // Explicit manual mappings for specific muscle queries to bridge cleanly to visual slugs
    if (cleaned == 'traps' || cleaned == 'trapezius') {
      return [BodyPartSlug.trapezius];
    }
    if (cleaned == 'lower back' || cleaned == 'erector spinae' ||
        cleaned == 'erectors' || cleaned == 'spinal erectors') {
      return [BodyPartSlug.lowerBack];
    }
    if (cleaned == 'adductor' || cleaned == 'adductors' ||
        cleaned == 'hip adductor' || cleaned == 'hip adductors') {
      return [BodyPartSlug.adductor];
    }
    if (cleaned == 'forearm' || cleaned == 'forearms') {
      return [BodyPartSlug.forearm];
    }
    if (cleaned.contains('biceps') || cleaned == 'brachialis') {
      return [
        BodyPartSlug.biceps,
        BodyPartSlug.biceps_long,
        BodyPartSlug.biceps_short,
      ];
    }
    // Wger muscles that fall back to their Latin name (no name_en set)
    if (cleaned == 'soleus') {
      return [BodyPartSlug.calves];
    }
    if (cleaned == 'obliquus externus abdominis') {
      return [BodyPartSlug.obliques];
    }
    if (cleaned == 'serratus anterior') {
      return [BodyPartSlug.upperBack];
    }

    // 1. Resolve via canonical group, then map group → slug list
    // This handles aggregate groups like "Shoulders" -> [frontDeltoids, backDeltoids]
    final canonical = RecoveryDomainService.majorMuscleGroupFor(rawName);
    if (canonical != null) {
      return _canonicalToSlugs[canonical] ?? const [];
    }

    // 2. Try direct fromString (normalises underscores → dashes, trims, lowercases)
    final direct = BodyPartSlug.fromString(rawName);
    if (direct != null) return [direct];

    return const [];
  }

  /// Converts a full list of raw muscle names to [BodyPartHighlightData]
  /// entries.
  ///
  /// Duplicate slugs are deduplicated — the first occurrence wins (earlier
  /// muscles in the list take precedence, so primary muscles beat secondary
  /// ones when this helper is called separately for each list).
  ///
  /// [intensity] is applied to every resulting slug (1–5).
  static List<BodyPartHighlightData> toHighlightData(
    List<String> muscleNames, {
    required int intensity,
  }) {
    final seen = <BodyPartSlug>{};
    final result = <BodyPartHighlightData>[];

    for (final name in muscleNames) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(BodyPartHighlightData(slug: slug, intensity: intensity));
        }
      }
    }

    return result;
  }

  /// Merges primary and secondary muscle highlight lists, ensuring primary
  /// muscles always win when the same slug appears in both lists.
  ///
  /// Primary muscles → [primaryIntensity] (default 5).
  /// Secondary muscles → [secondaryIntensity] (default 2).
  static List<BodyPartHighlightData> mergedHighlights({
    required List<String> primaryMuscles,
    required List<String> secondaryMuscles,
    int primaryIntensity = 5,
    int secondaryIntensity = 2,
  }) {
    final seen = <BodyPartSlug>{};
    final result = <BodyPartHighlightData>[];

    // Primary muscles first — they own the slug
    for (final name in primaryMuscles) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(
            BodyPartHighlightData(slug: slug, intensity: primaryIntensity),
          );
        }
      }
    }

    // Secondary muscles — only add slugs not already claimed
    for (final name in secondaryMuscles) {
      for (final slug in fromRawName(name)) {
        if (seen.add(slug)) {
          result.add(
            BodyPartHighlightData(slug: slug, intensity: secondaryIntensity),
          );
        }
      }
    }

    return result;
  }

  /// Returns only those highlights that are visible on [side].
  ///
  /// Use this when rendering a single [BodySide] view so that e.g.
  /// [BodyPartSlug.frontDeltoids] is not passed to a back-view widget
  /// (where it would render on an invisible region).
  static List<BodyPartHighlightData> forSide(
    List<BodyPartHighlightData> highlights,
    BodySide side,
  ) {
    return highlights.where((h) {
      final slugSide = _slugSide[h.slug];
      // If slug has no side mapping, show it on both views
      return slugSide == null || slugSide == side;
    }).toList(growable: false);
  }
}
