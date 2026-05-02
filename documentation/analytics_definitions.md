# Analytics Definitions

This file keeps stable terminology that is still useful across analytics
documentation. Current Statistics behavior is documented in
[statistics_module.md](statistics_module.md).

## Work Set

A work set is a completed, non-warmup set that contributes to analytics when it
has enough logged training signal for the metric being calculated.

- Tonnage and PR metrics require a positive `weightKg` and positive `reps`.
- Muscle recovery can include completed rep-based bodyweight strength work even
  when `weightKg` is null or zero.
- Obvious cardio categories and exercise names are excluded from muscle
  recovery stimulus even when catalog muscle mappings exist.

## Set Types

- Warm-up sets are excluded from volume, PR, and muscle recovery calculations.
- Failure sets count as work sets and are treated as very high effort.
- Dropsets count as work sets and contribute their own volume.

## Volume Terms

- Exercise tonnage: `sum(weightKg * reps)` for qualifying work sets of one
  exercise.
- Session tonnage: exercise tonnage summed across the workout.
- Muscle equivalent sets: primary muscles receive `1.0`, secondary muscles
  receive `0.5`.

## Personal Records

Estimated 1RM uses the Brzycki formula for qualifying sets:

```text
weight * (36 / (37 - reps))
```

Rep-max PRs are grouped into durable brackets: `1`, `2-3`, `4-6`, `7-10`,
`11-15`, and `15+` reps.

## Recovery Heuristic

Recovery is a training-log heuristic for planning, not a physiological
diagnosis or clinical prediction. Current recovery behavior, windows, pressure
calibration, and limitations are documented in
[statistics_module.md](statistics_module.md#recoveryreadiness-heuristic).

## Known Limitations

- Secondary-muscle weighting is still coarse.
- Recovery does not model systemic fatigue, soreness, pain, injury, stress,
  sleep debt, deloads, or training age.
- Exercise mapping changes can affect historical analytics unless mappings are
  snapshotted in a future schema.
