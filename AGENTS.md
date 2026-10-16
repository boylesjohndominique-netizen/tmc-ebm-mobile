# tmcebms — Flutter mobile app

App-specific rules. Shared rules are in `../AGENTS.md`.

## Facts
- Flutter stable 3.44, Dart SDK `>=3.6 <4`. State management: `provider`
  (`ChangeNotifier`).
- Originally a frontend-only prototype with mock data; `lib/data/api_service.dart`
  now talks to the Laravel API, but most app logic still lives in
  `lib/state/app_state.dart`.
- Layout: `lib/app` (shell/theme/routes), `lib/models`, `lib/data`, `lib/state`,
  `lib/screens/<module>` (auth, dashboard, equipment, borrowing, returns, history,
  notifications, profile, onboarding, splash), `lib/widgets` (shared UI).

## Commands (run from `tmcebms/`)
- `flutter pub get`
- `dart format lib test`
- `flutter analyze`
- `flutter test test/<file>_test.dart` — targeted; `flutter test` for the suite

## Rules
- Follow the existing `provider` + `ChangeNotifier` pattern; keep app logic in
  `lib/state/app_state.dart`. Reuse `lib/widgets/` and `lib/models/` — do not
  duplicate.
- Keep layouts responsive and light/dark theme behavior consistent (theme in
  `lib/app`); check the screen you change in both themes.
- Handle loading, error, empty, and success states for anything that fetches or
  mutates data.
- Use `async`/`await` correctly; guard `setState`/`notifyListeners` with mounted
  checks and avoid unnecessary rebuilds (`const`, scoped listeners).
- Preserve navigation, authentication, and API integration when editing.
- Keep `flutter analyze` clean (lints: `analysis_options.yaml`, `flutter_lints`).
