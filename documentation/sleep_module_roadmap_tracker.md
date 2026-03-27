# Sleep Module Issue Roadmap (Parent / Tracker)

This document is the canonical parent/tracker checklist for the Sleep Module rollout.

## Goal

Provide a single parent/tracker reference for the full Sleep Module implementation roadmap, including sequencing, boundaries, and milestone groupings.

## Scope

- Track and link all child issues (1–31).
- Preserve recommended execution order and milestone grouping.
- Preserve architecture boundaries (raw → canonical → derived layering; Statistics consumes Sleep outputs).

## Non-goals

- Implementing Sleep Module code directly in this tracker.
- Replacing detailed design docs contained in child issues.

## Milestone groups (recommended)

- Foundations: 1–5
- Platform ingestion: 6–7
- Canonical mapping: 8–9
- Normalization + repair: 10–11
- Analytics: 12–14
- Scoring: 15
- Repository/orchestration: 16–17
- UI foundations + wiring: 18–20
- UI screens: 21–26
- Aggregation + overview: 27–28
- Integration + polish + quality: 29–31

## Ordered child-issue checklist (1–31)

> Maintainer note: replace each `TBD` with the concrete GitHub issue link for that child issue.

### Foundations (1–5)
- [ ] 1. Child issue 1 — link: TBD
- [ ] 2. Child issue 2 — link: TBD
- [ ] 3. Child issue 3 — link: TBD
- [ ] 4. Child issue 4 — link: TBD
- [ ] 5. Child issue 5 — link: TBD

### Platform ingestion (6–7)
- [ ] 6. Child issue 6 — link: TBD
- [ ] 7. Child issue 7 — link: TBD

### Canonical mapping (8–9)
- [ ] 8. Child issue 8 — link: TBD
- [ ] 9. Child issue 9 — link: TBD

### Normalization + repair (10–11)
- [ ] 10. Child issue 10 — link: TBD
- [ ] 11. Child issue 11 — link: TBD

### Analytics (12–14)
- [ ] 12. Child issue 12 — link: TBD
- [ ] 13. Child issue 13 — link: TBD
- [ ] 14. Child issue 14 — link: TBD

### Scoring (15)
- [ ] 15. Child issue 15 — link: TBD

### Repository/orchestration (16–17)
- [ ] 16. Child issue 16 — link: TBD
- [ ] 17. Child issue 17 — link: TBD

### UI foundations + wiring (18–20)
- [ ] 18. Child issue 18 — link: TBD
- [ ] 19. Child issue 19 — link: TBD
- [ ] 20. Child issue 20 — link: TBD

### UI screens (21–26)
- [ ] 21. Child issue 21 — link: TBD
- [ ] 22. Child issue 22 — link: TBD
- [ ] 23. Child issue 23 — link: TBD
- [ ] 24. Child issue 24 — link: TBD
- [ ] 25. Child issue 25 — link: TBD
- [ ] 26. Child issue 26 — link: TBD

### Aggregation + overview (27–28)
- [ ] 27. Child issue 27 — link: TBD
- [ ] 28. Child issue 28 — link: TBD

### Integration + polish + quality (29–31)
- [ ] 29. Child issue 29 — link: TBD
- [ ] 30. Child issue 30 — link: TBD
- [ ] 31. Child issue 31 — link: TBD

## Definition of done

- [ ] All child issues 1–31 exist and are linked from this tracker.
- [ ] Sequencing and milestone grouping remain visible and up to date.
- [ ] Architecture boundaries remain explicit:
  - [ ] Raw ingestion persists raw records.
  - [ ] Canonical layer maps source-specific data into app canonical representation.
  - [ ] Derived/analytics/scoring build on canonical data (not raw provider payloads).
  - [ ] Statistics tab consumes Sleep aggregates; Sleep internals remain encapsulated.
