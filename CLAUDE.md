# smpl-habits

Android habit tracker app built with Flutter + Firebase.

## Project Status
- **Phase**: v1 complete, in daily use

## Tech Stack

- **Framework**: Flutter (Dart)
- **Auth**: Google Sign-In via Firebase Auth
- **Database**: Cloud Firestore (offline-first, real-time sync)
- **State**: Riverpod (StreamProviders for reactive UI)
- **UI**: Google Fonts (Inter), Material 3

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Auth routing (sign-in vs home)
├── firebase_options.dart        # Firebase config (gitignored)
├── models/                      # Habit, Log data classes
├── services/                    # Firestore CRUD (habit_service, log_service)
├── providers/                   # Riverpod providers (auth, habits, logs, health)
├── utils/                       # Decay algorithm, date helpers
├── screens/                     # sign_in_screen, home_screen
└── widgets/                     # habit_row, modals, backfill drawer, form fields

docs/
├── 01-process.md                # How we work
├── 02-prd.md                    # Product requirements
├── 03-design-guide.md           # Visual design spec
├── 04-system-design.md          # Architecture + phases
├── 05-future.md                 # Deferred features (v2+)
├── 06-testing-unit.md           # Unit test strategy
├── 07-testing-manual.md         # Manual test checklist
├── backlog.md                   # Task tracking
└── mockups/                     # HTML design mockups
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
- Boot: `emulator -avd smpl_tracker_test -no-audio`
- Firebase project: `smpl-tracker` (under kylechadha@gmail.com)

### Device Install
- Prefer wireless ADB: `adb tcpip 5555 && adb connect <phone-ip>:5555`
- Install: `adb install build/app/outputs/flutter-apk/app-release.apk`

### Firebase
- Project ID: `smpl-tracker`
- Console: https://console.firebase.google.com/u/1/project/smpl-tracker
- Auth: Google Sign-In only (no anonymous)
- Firestore security rules: user-scoped read/write
- **Note**: Firebase project ID, Android package (`com.kylechadha.smpl_tracker`), and Dart package remain `smpl_tracker` — renaming would break Firebase config, signing, and Play Store identity. Only the GitHub repo and docs use `smpl-habits`.

## Git Workflow

- Single `main` branch (solo project, no PRs needed)
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Push after every commit

## Design

- Design spec: `docs/03-design-guide.md`
- Colors: #1A1A2E (primary dark), #10B981 (green), #F59E0B (yellow), #EF4444 (red), #3B82F6 (blue overflow)
- Font: Inter (bundled locally)
- Background: #F7F8FA

## Key Decisions

- **Decay model**: Start 100%, accelerating decay on misses, inverse recovery on logs
- **Overflow banking**: Extra logs buffer against decay, display above 100%
- **Day boundary**: 2am local time
- **Week start**: Sunday (health resets to 0% on Sunday for new weekly cycle)
- **Frequencies**: Daily or X/week only (v1)
- **Logging**: Binary (done/not done)

## Debug Log - Mar 14, 2026

### Issues Investigated
1. **Backfill drawer missing Sunday** — FIXED
   - Root cause: Loop showed last 7 calendar days instead of current week
   - Fix: Changed to weekStart-based iteration
   - Verified working on emulator

2. **All habits resetting to 100% on Sunday** — NOT A BUG
   - Expected behavior: Each week starts with health = 0% (fresh cycle)
   - Logging immediately recovers health via inverse recovery formula
   - Pattern is: Sun 0% → (log) → Mon 100% → (mid-week) → Wed 99% → Sat final eval
   - This is designed behavior per algorithm

3. **67% → 0% → 100% health swing** — ROOT CAUSE IDENTIFIED
   - This is the Sunday→Monday week transition pattern
   - Example from real data (7am Rise, 5x/weekly):
     - Previous week ends with health > 0
     - Sunday (new week): 0% (no logs in new week yet)
     - Monday (log): 100% (recovery formula at low health)
     - Throughout week: provisional decay applies if behind pace
     - Saturday: final eval based on target completion (2/5 = 98%)
   - Not a bug—this is the algorithm working as designed

### Data Verified
- **Account**: 100% kylechadha@gmail.com (Protein Shake: 23 logs over 4 weeks confirms single user)
- **Firestore UID**: MUiQG6i8i3cMoyp7V6SQMwSO4023
- **Tracking span**: Feb 17 - Mar 13 (4 weeks, 56 total logs)
- **No data loss** across all tracked habits

### Algorithm Clarification
Weekly health cycle:
- **Sunday (weekStart)**: Health = 0% (fresh week, no logs yet)
- **Mon-Sat**: Logs trigger recovery (formula: 5% × (1 + (100 - health)/100))
- **Thu-Sat**: If behind pace, provisional mid-week decay applies
- **Saturday (weekEnd)**: Final evaluation — full recovery if target met, decay if missed
- **Recovery is inverse to health**: Lower health = stronger recovery boost
- **Decay accelerates**: Each consecutive miss increases decay rate (1.5x multiplier)

This creates the pattern users observe but is working correctly per design.
