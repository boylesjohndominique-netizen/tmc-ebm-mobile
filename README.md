# TMCEBMS — Trinidad Municipal College Equipment Borrowing and Tracking Management System

A Flutter frontend prototype (mock data only, no backend) for browsing, requesting, and
tracking borrowed school equipment.

## Getting Started

```bash
flutter pub get
flutter run
```

This project was built as a **frontend-only prototype**. There is no database, Firebase,
or API — all data lives in `lib/data/` and is held in memory for the session via
`lib/state/app_state.dart` (a `ChangeNotifier` using the `provider` package).

## Demo accounts

| Role    | Email             | Password    |
|---------|-------------------|-------------|
| Student | student@tmc.edu   | password123 |
| Faculty | faculty@tmc.edu   | password123 |
| Staff   | staff@tmc.edu     | password123 |

New accounts created through **Register** are added to the in-memory user list and can
log in immediately (data resets on app restart, since there is no persistence layer).

## Project structure

```
lib/
├── main.dart
├── app/            # app shell, theme, routes
├── models/         # plain Dart data models
├── data/           # mock/seed data, kept separate from UI
├── state/          # AppState (ChangeNotifier) — all app logic lives here
├── screens/        # one folder per module (auth, dashboard, equipment, ...)
└── widgets/        # shared, reusable UI components
```

Replacing mock data with a real backend later mainly means swapping the bodies of the
methods in `lib/state/app_state.dart` for real API/database calls — the screens already
consume that state through `provider` and don't need to change.

## Feature coverage

Splash → Onboarding (3 pages) → Login/Register/Forgot Password → Dashboard →
Equipment (browse/search/filter/details) → Borrowing (request, date pickers, status,
cancel) → Returns (view borrowed, due/overdue indicators, submit return) → History
(borrowing + return tabs, transaction details) → Notifications (read/unread, mark all
read) → Profile (view, edit, change password, logout).
