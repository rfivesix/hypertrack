import 'goal_models.dart';

enum AdaptiveDietPhase {
  cut,
  maintain,
  bulk,
}

extension AdaptiveDietPhaseGoalMapping on BodyweightGoal {
  AdaptiveDietPhase get canonicalDietPhase {
    switch (this) {
      case BodyweightGoal.loseWeight:
        return AdaptiveDietPhase.cut;
      case BodyweightGoal.maintainWeight:
        return AdaptiveDietPhase.maintain;
      case BodyweightGoal.gainWeight:
        return AdaptiveDietPhase.bulk;
    }
  }
}

class AdaptiveDietPhaseTrackingState {
  static const int currentStateVersion = 1;

  final AdaptiveDietPhase confirmedPhase;
  final DateTime confirmedPhaseStartDay;
  final AdaptiveDietPhase? pendingPhase;
  final DateTime? pendingPhaseFirstSeenDay;
  final int stateVersion;

  const AdaptiveDietPhaseTrackingState({
    required this.confirmedPhase,
    required this.confirmedPhaseStartDay,
    required this.pendingPhase,
    required this.pendingPhaseFirstSeenDay,
    this.stateVersion = currentStateVersion,
  });

  factory AdaptiveDietPhaseTrackingState.bootstrap({
    required AdaptiveDietPhase phase,
    required DateTime asOfDay,
  }) {
    return AdaptiveDietPhaseTrackingState(
      confirmedPhase: phase,
      confirmedPhaseStartDay: normalizeDay(asOfDay),
      pendingPhase: null,
      pendingPhaseFirstSeenDay: null,
    );
  }

  bool get hasPendingPhaseChange => pendingPhase != null;

  bool get isValid {
    final hasPendingPair =
        pendingPhase != null && pendingPhaseFirstSeenDay != null;
    final hasNoPendingPair =
        pendingPhase == null && pendingPhaseFirstSeenDay == null;
    return hasPendingPair || hasNoPendingPair;
  }

  int confirmedPhaseAgeDays(DateTime asOfDay) {
    return _inclusiveAgeDays(
      startDay: confirmedPhaseStartDay,
      asOfDay: normalizeDay(asOfDay),
    );
  }

  int? pendingPhaseAgeDays(DateTime asOfDay) {
    final start = pendingPhaseFirstSeenDay;
    if (pendingPhase == null || start == null) {
      return null;
    }
    return _inclusiveAgeDays(
      startDay: start,
      asOfDay: normalizeDay(asOfDay),
    );
  }

  AdaptiveDietPhaseTrackingState reconcile({
    required AdaptiveDietPhase observedPhase,
    required DateTime asOfDay,
    int confirmationWindowDays = 7,
  }) {
    final normalizedDay = normalizeDay(asOfDay);
    final minimumWindowDays = confirmationWindowDays.clamp(1, 365).toInt();

    if (observedPhase == confirmedPhase) {
      if (!hasPendingPhaseChange) {
        return this;
      }
      return AdaptiveDietPhaseTrackingState(
        confirmedPhase: confirmedPhase,
        confirmedPhaseStartDay: confirmedPhaseStartDay,
        pendingPhase: null,
        pendingPhaseFirstSeenDay: null,
      );
    }

    if (pendingPhase != observedPhase) {
      return AdaptiveDietPhaseTrackingState(
        confirmedPhase: confirmedPhase,
        confirmedPhaseStartDay: confirmedPhaseStartDay,
        pendingPhase: observedPhase,
        pendingPhaseFirstSeenDay: normalizedDay,
      );
    }

    final candidateFirstSeen = pendingPhaseFirstSeenDay ?? normalizedDay;
    final candidateStableDays = _inclusiveAgeDays(
      startDay: candidateFirstSeen,
      asOfDay: normalizedDay,
    );
    if (candidateStableDays >= minimumWindowDays) {
      // Intentional semantics: confirmed phase age resets at confirmation
      // moment, not when the pending candidate was first seen.
      return AdaptiveDietPhaseTrackingState(
        confirmedPhase: observedPhase,
        confirmedPhaseStartDay: normalizedDay,
        pendingPhase: null,
        pendingPhaseFirstSeenDay: null,
      );
    }

    if (pendingPhaseFirstSeenDay == null) {
      return AdaptiveDietPhaseTrackingState(
        confirmedPhase: confirmedPhase,
        confirmedPhaseStartDay: confirmedPhaseStartDay,
        pendingPhase: pendingPhase,
        pendingPhaseFirstSeenDay: normalizedDay,
      );
    }

    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      'stateVersion': stateVersion,
      'confirmedPhase': confirmedPhase.name,
      'confirmedPhaseStartDay':
          normalizeDay(confirmedPhaseStartDay).toIso8601String(),
      'pendingPhase': pendingPhase?.name,
      'pendingPhaseFirstSeenDay': pendingPhaseFirstSeenDay == null
          ? null
          : normalizeDay(pendingPhaseFirstSeenDay!).toIso8601String(),
    };
  }

  factory AdaptiveDietPhaseTrackingState.fromJson(Map<String, dynamic> json) {
    final confirmedPhaseRaw = json['confirmedPhase'] as String?;
    final pendingPhaseRaw = json['pendingPhase'] as String?;
    final confirmedStartRaw = json['confirmedPhaseStartDay'] as String?;
    final pendingFirstSeenRaw = json['pendingPhaseFirstSeenDay'] as String?;

    final confirmedPhase = AdaptiveDietPhase.values.firstWhere(
      (phase) => phase.name == confirmedPhaseRaw,
      orElse: () => AdaptiveDietPhase.maintain,
    );
    final confirmedPhaseStartDay = normalizeDay(
      DateTime.tryParse(confirmedStartRaw ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
    final pendingPhase = pendingPhaseRaw == null
        ? null
        : AdaptiveDietPhase.values.firstWhere(
            (phase) => phase.name == pendingPhaseRaw,
            orElse: () => confirmedPhase,
          );
    final pendingPhaseFirstSeenDay = pendingPhase == null
        ? null
        : normalizeDay(
            DateTime.tryParse(pendingFirstSeenRaw ?? '') ??
                confirmedPhaseStartDay,
          );

    return AdaptiveDietPhaseTrackingState(
      confirmedPhase: confirmedPhase,
      confirmedPhaseStartDay: confirmedPhaseStartDay,
      pendingPhase: pendingPhase,
      pendingPhaseFirstSeenDay: pendingPhaseFirstSeenDay,
      stateVersion: (json['stateVersion'] as int?) ?? currentStateVersion,
    );
  }

  static DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int _inclusiveAgeDays({
    required DateTime startDay,
    required DateTime asOfDay,
  }) {
    if (asOfDay.isBefore(startDay)) {
      return 0;
    }
    return asOfDay.difference(startDay).inDays + 1;
  }
}

class BayesianObservationPhaseContext {
  final AdaptiveDietPhase confirmedPhase;
  final int confirmedPhaseAgeDays;
  final AdaptiveDietPhase? pendingPhase;
  final int? pendingPhaseAgeDays;

  const BayesianObservationPhaseContext({
    required this.confirmedPhase,
    required this.confirmedPhaseAgeDays,
    required this.pendingPhase,
    required this.pendingPhaseAgeDays,
  });

  factory BayesianObservationPhaseContext.bootstrap({
    required AdaptiveDietPhase phase,
  }) {
    return BayesianObservationPhaseContext(
      confirmedPhase: phase,
      confirmedPhaseAgeDays: 1,
      pendingPhase: null,
      pendingPhaseAgeDays: null,
    );
  }

  factory BayesianObservationPhaseContext.fromTrackingState({
    required AdaptiveDietPhaseTrackingState trackingState,
    required DateTime asOfDay,
  }) {
    return BayesianObservationPhaseContext(
      confirmedPhase: trackingState.confirmedPhase,
      confirmedPhaseAgeDays: trackingState.confirmedPhaseAgeDays(asOfDay),
      pendingPhase: trackingState.pendingPhase,
      pendingPhaseAgeDays: trackingState.pendingPhaseAgeDays(asOfDay),
    );
  }

  bool get hasPendingPhaseChange => pendingPhase != null;
}
