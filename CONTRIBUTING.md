# Contributing to Train Libre

Welcome to the Train Libre repository! We appreciate your interest in contributing to this offline-first, privacy-focused fitness application. As a solo-maintained or small open-source project, keeping the codebase clean, stable, and strictly architectural is critical.

## Local Setup Routine

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rfivesix/train-libre.git
   cd train-libre
   ```

2. **Resolve Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Code Generation:**
   Train Libre relies on Drift and other code generators. You must recompile the generated code whenever you change schemas or database files.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Localization Generation:**
   If you change any `.arb` files, regenerate the localization files:
   ```bash
   flutter gen-l10n
   ```

5. **Run the App:**
   ```bash
   flutter run
   ```

## Development Constraints & Style Rules

- **Clean Architecture & Strict Layering:** The codebase follows an Enterprise Grade Clean Architecture standard. Keep pure domain entities isolated from Flutter widgets and infrastructure code. Return models from repository contracts, and keep `DatabaseHelper` and local data sources devoid of complex business logic.
- **Dart Formatting:** All code must conform to the standard Dart format. Run `dart format .` before submitting a pull request. However, avoid formatting entire large, untouched files to prevent unrelated formatting noise in the diff.
- **Static Analysis:** Ensure your changes pass the Flutter analyzer without warnings. Run `flutter analyze` locally.
- **Visual Changes:** If your pull request introduces UI modifications, you *must* attach layout screenshots (for both Light and Dark mode, if applicable) to your PR description.
- **Feature Modules:** New feature modules should be spawned in the `lib/features/` folder following the pure layer isolation pattern described in `documentation/architecture.md`.

## Submitting Pull Requests

- Work on targeted, single-responsibility branches.
- Provide a clear and concise description of the motivation and changes in the pull request.
- Reference any related issues or discussions.
- Ensure all CI checks (formatting, analysis, and tests if applicable) pass successfully.

Thank you for helping build a powerful, private fitness tracker!
