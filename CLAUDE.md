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

## Testing

- **Red/Green/Red workflow**: Before changing behavior, ensure existing tests cover it. Change code → old test fails (red). Write/update tests for new behavior → tests pass (green). This confirms both that the old behavior was captured and the new behavior is correct.
- **Every change needs a test**: Bug fixes get a regression test. Features get unit tests for the core logic. No shipping code changes without corresponding test changes.
- **Test the algorithm, not the widget**: Decay/health logic is pure functions — test with unit tests. Widget layout is verified on emulator.
- Run `flutter test` before every commit.

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
- **Default new habit**: Weekly 5x/week (Mon-Fri pattern)
- **Reset score**: Sets `healthResetAt` to now; algorithm skips days before that date, health restarts at 100%, logs kept
- **Pause habit**: `isPaused` flag; health shows neutral, tap/swipe disabled, PAUSED badge shown; unpause resets health via `healthResetAt`
- **Drag to reorder**: Explicit drag handle (grip dots) via `ReorderableDragStartListener`, long press opens edit modal
- **Sort order**: `max(sort_order) + 1` on create (not `docs.length`) to avoid collisions after deletions
- **Backfill drawer**: Rolling last 7 days (not week boundaries) so previous day is always accessible

## Emulator Testing

- AVD: `smpl_tracker_test` (Pixel 7, API 34, google_apis_playstore ARM64)
- Package: `com.smpltracker.smpl_tracker` (launch: `adb shell am start -n com.smpltracker.smpl_tracker/.MainActivity`)
- **ADB touch input**: Flutter rejects `PointerDeviceKind.unknown` from ADB by default. Fixed via `_AppScrollBehavior` in `app.dart`. Without this, only widgets outside scrollables (like FAB) respond to ADB taps.
- **Coordinate offset**: ADB coordinates don't map 1:1 to screenshot pixels on this emulator. Use pointer overlay (`adb shell settings put system pointer_location 1`) to calibrate. The mapping varies by emulator session.
- **Debug vs Release**: Debug APK triggers ANR dialogs on emulator due to frame drops. Use release APK for emulator QC.
- **hw.keyboard**: Setting `hw.keyboard=yes` in AVD config breaks touch input. Keep it at `no`.

## Debug Log - Jun 9, 2026

### Features Added
1. **Reset score** -- `healthResetAt` field on Habit; algorithm skips days before reset date
2. **Pause/unpause habit** -- `isPaused` field; dimmed UI, PAUSED badge, tap/swipe disabled, unpause resets health
3. **Drag-to-reorder** -- Explicit drag handle via `ReorderableDragStartListener`, decoupled from long-press edit
4. **Default weekly 5x** -- New habits default to weekly frequency with 5 selected

### Bugs Fixed
1. **New habit health 97-99%** -- Provisional mid-week penalty missing grace period check (commit 3560176)
2. **Backfill drawer missing previous day** -- Changed from week boundaries (Sun-Sat) to rolling last 7 days (commit 3560176)
3. **Sort order collisions** -- `max(sort_order)+1` instead of `docs.length` (commit 3560176)
4. **DST bug in daysSinceCreation** -- Used un-normalized `date` instead of `dateMidnightNorm` (commit 60dfd26)
5. **getWeekEnd DST susceptibility** -- DateTime constructor instead of Duration addition (commit 60dfd26)
6. **Paused habit swipe loophole** -- Slidable disabled when paused to prevent backfill logging

### Test Coverage: 65 tests (17 new)
- Grace period on mid-week penalty (4 tests)
- healthResetAt reset score (3 tests)
- healthStartDate getter (3 tests)
- getWeekEnd/getWeekStart DST safety (3 tests)
- Rolling 7-day date math (4 tests: month boundary, DST, year boundary, leap year)

### Quality Agent Reviews
- **Code reviewer**: Found paused-habit-swipe loophole (fixed)
- **Architect**: Suggested renaming `healthResetAt` to `healthEpoch` (deferred, getter `healthStartDate` is clear enough)
- **Security**: Low risk, no issues for single-user app
- **Design**: Normalized icon sizes to 24px, outline style, improved touch targets and label contrast

---

## Debug Log - Mar 15, 2026

### Critical Bugs Fixed (Decay Algorithm)

1. **DST DateTime Bug** ✅ FIXED (commit 60edb1e)
   - **Root cause**: `DateTime.subtract(Duration(days: N))` on DST boundaries leaves fractional hours
   - **Example**: `DateTime(2026, 3, 9).subtract(Duration(days: 1))` = `2026-03-07 23:00:00` (not midnight)
   - **Impact**: Date comparisons like `date == weekEnd` failed because time components didn't match
   - **Consequence**: Saturday week evaluations never fired, health stayed at 100% instead of decaying
   - **Fix**: Normalize all dates to midnight before comparison: `DateTime(date.year, date.month, date.day)`
   - **Verified**: 48/48 unit tests passing, including DST edge cases

2. **Sunday Boundary Condition Bug** ✅ FIXED (commit 60edb1e)
   - **Root cause**: Condition `date.isAfter(weekStart)` is false when `date == weekStart` (Sunday)
   - **Impact**: Sunday excluded from mid-week provisional evaluation, allowed health to stay at invalid levels
   - **Fix**: Changed to `(dateMidnightNorm == weekStartMidnight || dateMidnightNorm.isAfter(weekStartMidnight))`
   - **Verified**: RED test "Sunday should not jump to 100% after missing previous week" now passing

3. **Decay Too Steep** ✅ IMPROVED (commit b477fbf)
   - **Issue**: `decayAcceleration = 1.5` caused ~33% health loss per missed week for 5x/week habits
   - **User feedback**: "shouldn't go sharp from 67% to 0%, should be 10-20% loss per week"
   - **Change**: `decayAcceleration = 1.1` → ~15% loss per missed week (gentle, exponential)
   - **Formula effect**: Decay = 5% × 1.1^(misses-1) scales smoothly instead of sharply

### Backfill Drawer Fix (Previous Session)
- ✅ FIXED: Drawer now shows Sunday-Saturday of current week (was missing Sunday)
- Root cause: Loop showed last 7 calendar days instead of week boundaries
- Commit: 92911cb

### Data & Testing
- **No data loss**: All 56 logs across 4 weeks verified in Firestore
- **Unit tests**: 48/48 passing, including 3 critical RED tests for the bugs
- **Emulator verification**: App builds and displays correct health values (7am Rise 38%, not 0%/100%)
- **Test coverage**: Grace periods, DST boundaries, weekly evals, mid-week decay, recovery formula all tested

### Algorithm Behavior (Now Correct)
Weekly cycle for 5x/week habit:
- **Sunday (new week)**: Health = 0% (fresh slate, applies provisional penalty if no logs)
- **Mon-Sat**: Logs trigger recovery; missed pace triggers gradual decay
- **Sat (weekEnd)**: Final eval — recovery if ≥5 logs, decay if <5
- **Recovery formula**: 5% × (1 + (100 - health)/100) — scales with deficit
- **Decay formula**: 5% × 1.1^(misses-1) — gentle acceleration per consecutive miss
- **No sharp jumps**: Smooth transitions, no health > 100% without extra logs
