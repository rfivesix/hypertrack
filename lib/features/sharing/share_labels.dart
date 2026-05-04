import '../../generated/app_localizations.dart';
import 'share_set_type.dart';

class ShareLabels {
  const ShareLabels({
    required this.appName,
    required this.sharedWithTrainLibre,
    required this.freeWorkoutTitle,
    required this.duration,
    required this.volume,
    required this.exercises,
    required this.sets,
    required this.set,
    required this.setNumber,
    required this.reps,
    required this.kg,
    required this.km,
    required this.min,
    required this.warmup,
    required this.work,
    required this.failure,
    required this.dropset,
    required this.superset,
    required this.other,
    required this.warmupSuffix,
    required this.failureSuffix,
    required this.dropsetSuffix,
    required this.supersetSuffix,
    required this.otherSuffix,
    required this.setTypeCount,
    required this.setTypeCompact,
    required this.moreExercises,
    required this.githubUrl,
    required this.shareImageSummary,
    required this.shareImageExercises,
    required this.shareImageMuscleFocus,
    required this.shareImageMinimal,
  });

  factory ShareLabels.fromL10n(AppLocalizations l10n) {
    return ShareLabels(
      appName: l10n.appTitle,
      sharedWithTrainLibre: l10n.sharedWithTrainLibre,
      freeWorkoutTitle: l10n.freeWorkoutTitle,
      duration: l10n.durationLabel,
      volume: l10n.volume,
      exercises: l10n.shareExercisesLabel,
      sets: l10n.shareSetsLabel,
      set: l10n.shareSetLabel,
      setNumber: l10n.shareSetNumber,
      reps: l10n.repsShort,
      kg: 'kg',
      km: 'km',
      min: 'min',
      warmup: l10n.setTypeWarmup,
      work: l10n.setTypeWork,
      failure: l10n.setTypeFailure,
      dropset: l10n.setTypeDropset,
      superset: l10n.setTypeSuperset,
      other: l10n.setTypeOther,
      warmupSuffix: l10n.setTypeWarmupSuffix,
      failureSuffix: l10n.setTypeFailureSuffix,
      dropsetSuffix: l10n.setTypeDropsetSuffix,
      supersetSuffix: l10n.setTypeSupersetSuffix,
      otherSuffix: l10n.setTypeOtherSuffix,
      setTypeCount: (type, count) => _setTypeCount(l10n, type, count),
      setTypeCompact: (type, count) => _setTypeCompact(l10n, type, count),
      moreExercises: l10n.moreExercises,
      githubUrl: 'https://github.com/rfivesix/train-libre',
      shareImageSummary: l10n.shareImageSummary,
      shareImageExercises: l10n.shareImageExercises,
      shareImageMuscleFocus: l10n.shareImageMuscleFocus,
      shareImageMinimal: l10n.shareImageMinimal,
    );
  }

  static String _setTypeCount(
    AppLocalizations l10n,
    ShareSetType type,
    int count,
  ) {
    return switch (type) {
      ShareSetType.warmup => l10n.warmupSetCount(count),
      ShareSetType.work => l10n.workSetCount(count),
      ShareSetType.failure => l10n.failureSetCount(count),
      ShareSetType.dropset => l10n.dropsetCount(count),
      ShareSetType.superset => l10n.supersetSetCount(count),
      ShareSetType.other => l10n.otherSetCount(count),
    };
  }

  static String _setTypeCompact(
    AppLocalizations l10n,
    ShareSetType type,
    int count,
  ) {
    return switch (type) {
      ShareSetType.warmup => l10n.warmupCompactCount(count),
      ShareSetType.work => l10n.workCompactCount(count),
      ShareSetType.failure => l10n.failureCompactCount(count),
      ShareSetType.dropset => l10n.dropsetCompactCount(count),
      ShareSetType.superset => l10n.supersetCompactCount(count),
      ShareSetType.other => l10n.otherCompactCount(count),
    };
  }

  final String appName;
  final String sharedWithTrainLibre;
  final String freeWorkoutTitle;
  final String duration;
  final String volume;
  final String exercises;
  final String sets;
  final String set;
  final String Function(int number) setNumber;
  final String reps;
  final String kg;
  final String km;
  final String min;
  final String warmup;
  final String work;
  final String failure;
  final String dropset;
  final String superset;
  final String other;
  final String warmupSuffix;
  final String failureSuffix;
  final String dropsetSuffix;
  final String supersetSuffix;
  final String otherSuffix;
  final String Function(ShareSetType type, int count) setTypeCount;
  final String Function(ShareSetType type, int count) setTypeCompact;
  final String Function(int count) moreExercises;
  final String githubUrl;
  final String shareImageSummary;
  final String shareImageExercises;
  final String shareImageMuscleFocus;
  final String shareImageMinimal;
}
