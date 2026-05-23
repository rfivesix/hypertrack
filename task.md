# Phase 4: Sleep Scoring Engine Upgrade

## Objective
Replace the naive sleep scoring algorithm with the multidimensional Sleep Health Score (SHS v3) based on clinical consensus (AASM).

## Checklist

### 1. Update `SleepScoringInput`
- [x] Add `double? sleepOnsetHourLocal` to `SleepScoringInput` in `sleep_scoring_engine.dart`.
- [x] Add `double? rollingMidSleepSd` to `SleepScoringInput` in `sleep_scoring_engine.dart`.

### 2. Update `sleep_pipeline_service.dart`
- [x] Calculate `sleepOnsetHourLocal` using `session.startAtUtc.toLocal()`. We will anchor hours past noon to handle midnight cleanly (e.g., 1 AM = 25.0).
- [x] Calculate `rollingMidSleepSd` (7-14 day lookback) using the `lookbackSessions` and current batch sessions.
- [x] Pass these new fields into `SleepScoringInput`.

### 3. Rewrite Scoring Logic in `sleep_scoring_engine.dart`
Strictly follow the mathematical specifications:
- [x] **Dimension Weights**: Update `SleepScoringConfig` weights (Duration: 0.30, Continuity: 0.20, Architecture: 0.25, Timing: 0.15, Regularity: 0.10).
- [x] **Duration Score ($D$)**: Gaussian $\mu_T=7.5$, $\sigma_T=1.0$, plateau for 7-9h, clip $<5$ or $>10.5$.
- [x] **Continuity Score ($C$)**: $0.5 \cdot C_{SE} + 0.5 \cdot C_{WASO}$.
    - $C_{SE}$: $1 / (1 + \exp(-50 \cdot (SE - 0.90)))$
    - $C_{WASO}$: $1 / (1 + (\max(WASO - 20, 0) / 30)^2)$
- [x] **Architecture Score ($A$)**:
    - $A_{N3} = \min(1, N3/90) \cdot \exp(-(N3-90)^2 / (2 \cdot 40^2))$
    - $A_{REM} = \min(1, REM/100) \cdot \exp(-(REM-100)^2 / (2 \cdot 40^2))$
    - $P_{N1} = \exp(-(N1\% - 10)^2 / (2 \cdot 5^2))$ if $N1\% > 10\%$, else $1.0$
    - $A = (0.45 \cdot A_{N3} + 0.45 \cdot A_{REM}) \cdot P_{N1} + 0.10$
- [x] **Timing Score ($T_{circ}$)**:
    - $MS = \text{OnsetHour} + (\text{TST} / 2)$
    - Gaussian around 03:30 ($MS_{opt}=3.5$ which in 0-24 scale from midnight is 3.5, or anchored to noon it is 27.5. Wait, 03:30 AM is just 3.5 if we map correctly).
    - $P_{late} = \exp(-(MS - 5.5)^2 / (2 \cdot 0.5^2))$ if $MS > 5.5$
- [x] **Regularity Score ($R$)**: $1 / (1 + (MS_{sd} / 1.0)^2)$
- [x] **Clinical Hard Caps**:
    - Tier 1: If TST < 6h, N3 < 40m, REM < 60m, N1% > 20%, or MS > 5.5 -> Cap at 60.0.
    - Tier 2: If TST < 5h, SE < 75%, or WASO > 90m -> Cap at 40.0.

### 4. Verification
- [x] Run `flutter analyze` to ensure type safety.
- [x] Check signatures and verify mathematical transformations are well commented.

## Phase 5: Sleep Dashboard UI Upgrade

### Checklist
- [x] **Data Model Alignment**: Ensure that the `SleepScoringResult` computed in `SleepPipelineService` is preserved and attached to the `SleepDayOverviewData` structure passed down to the presentation layer.
- [x] **Create the Breakdown Widget**: Create `lib/features/sleep/presentation/widgets/sleep_score_breakdown_card.dart`
  - Accept `SleepScoringResult`.
  - Display progress rows: *Schlafdauer* (`durationScore`), *Kontinuität (WASO/SE)* (`continuityScore`), *Schlafphasen-Tiefe* (`architectureScore`), *Zirkadianes Timing* (`timingScore`), *Regelmäßigkeit* (`regularityScore`).
- [x] **Active Hard-Cap Indicator**: Inside the card, display warning banner if score was capped.
- [x] **UI Orchestration**: Inject `SleepScoreBreakdownCard` dynamically into the scrollable widget column right beneath the custom `Timeline` page/card section in the day overview layout.
- [x] **Verification**: Run `flutter analyze`.

## Phase 6: Native Android OOM Fix (MethodChannel)

### Objective
Fix the `java.lang.OutOfMemoryError` encountered during native-to-Flutter bridging of heart rate samples on the Sleep Detail Page.

### Checklist
- [x] **Time-Block Aggregation**: Implemented 1-minute bucket aggregation in `MainActivity.kt` to downsample high-frequency pulse data.
- [x] **Data Structure Resolution**: Calculate average BPM per bucket and map back to expected Flutter payload.
- [x] **Defensive Sizing**: Apply `pageSize = 2000` boundary to `ReadRecordsRequest`.
- [x] **Verification**: Android Gradle build succeeds (`./gradlew assembleDebug`).
