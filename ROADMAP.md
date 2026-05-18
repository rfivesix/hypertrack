# Train Libre Roadmap

## Mid-term

- Program library (“store”) of curated training plans (e.g. PPL, upper/lower, hypertrophy blocks) that can be copied into personal routines.
- Weekly training calendar to assign plans/routines to specific days (e.g. Mon Push, Wed Pull, Fri Legs) and see planned vs. completed sessions.
- More advanced training and nutrition goal logic (training/rest‑day profiles, simple refeed/high‑day patterns) on top of the adaptive TDEE estimator.
- Official Google Play Store release
- F-Droid Release

## Long-term

- Wearable-/watch‑first logging experiences for minimal‑friction set tracking.
- Strava and other privacy‑respecting FOSS ecosystem integrations where they make sense.
- Deeper AI‑assisted workflows (meal capture, planning) while keeping BYOK and strict on‑device validation.

## Ideas / Potential

These are early ideas, not commitments. They will only happen if they make sense for users and for the project.

- **muscle visualization**: Implement selected muscles on a model in various screens. A package that may be fits for this is https://github.com/timcreatedit/body_part_selector. But it looks very basic.

- **Optional low‑cost AI add‑on:** If there is enough demand, Train Libre might offer a privacy‑respecting subscription where the app manages the AI API key for you (no manual key setup, no per‑token billing hassle). The core app would stay open source, offline‑first, and fully usable without any subscription.

- **Optional private account & sync (self‑hostable first):** Long‑term, there could be an optional account layer for encrypted backup and multi‑device sync, designed to be self‑hostable (e.g. via a small Docker setup, possibly on top of something like Supabase or a similar backend).
  A public, centrally hosted instance might exist later, but would remain strictly optional — Train Libre should work fully without any account or external server.
