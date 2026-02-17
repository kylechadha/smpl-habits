# smpl-tracker

Android habit tracker app built with Flutter + Firebase.

## Project Status
- **Phase**: v1 complete (Phases 1-5 done)
- **Next step**: Sideload APK to physical device for daily use

## Tech Stack

- **Framework**: Flutter (Dart)
- **Auth**: Google Sign-In via Firebase Auth
- **Database**: Cloud Firestore (offline-first, real-time sync)
- **State**: Riverpod (StreamProviders for reactive UI)
- **UI**: Google Fonts (Inter), Material 3

## Project Structure

```
lib/
├── main.dart, app.dart          # Entry point, auth routing
├── models/                      # Habit, Log data classes
├── services/                    # Firestore CRUD wrappers
├── providers/                   # Riverpod providers (auth, habits, logs, health)
├── utils/                       # Decay algorithm, date helpers
├── screens/                     # Sign-in, home
└── widgets/                     # Habit row, modals, backfill drawer, shared form fields
```

## Key Files

- `lib/utils/decay.dart` - Health decay algorithm (core game mechanic)
- `lib/widgets/habit_row_wrapper.dart` - Data-fetching wrapper for presentational HabitRow
- `lib/widgets/habit_form_fields.dart` - Shared form widgets for add/edit modals
- `firestore.rules` - User-scoped security rules

## Development

### Commands
```bash
flutter run                        # Run on connected device/emulator
flutter build apk --debug         # Debug APK
flutter build apk --release       # Release APK
flutter analyze                    # Lint check
```

### Emulator
- AVD: `smpl_tracker_test` (Pixel 7, API 34, google_apis_playstore ARM64)
- Boot: `emulator -avd smpl_tracker_test`
- Firebase project: `smpl-tracker` (under kylechadha@gmail.com)

### Firebase
- Project ID: `smpl-tracker`
- Console: https://console.firebase.google.com/u/1/project/smpl-tracker
- Auth: Google Sign-In only (no anonymous)
- Firestore rules: user-scoped read/write

## Git Workflow

- Work directly on `main` (solo project, no PRs needed)
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Push after every commit

## Design

- Design spec: `docs/03-design-guide.md`
- Colors: #1A1A2E (primary dark), #10B981 (green), #F59E0B (yellow), #EF4444 (red), #3B82F6 (blue overflow)
- Font: Inter (all weights via google_fonts)
- Background: #F7F8FA

## Key Decisions

- **Decay model**: Start 100%, accelerating decay on misses, inverse recovery on logs
- **Overflow banking**: Extra logs buffer against decay, display above 100%
- **Day boundary**: 2am local time
- **Week start**: Sunday
- **Frequencies**: Daily or X/week only (v1)
- **Logging**: Binary (done/not done)
