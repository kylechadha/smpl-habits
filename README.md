# smpl-habits

A simple habit tracker built with Flutter and Firebase.

Most habit trackers use a "build up" model where you start at 0% and work toward 100%. This creates the wrong mental model — new habits feel like failures from day one. smpl-habits flips it: habits start at 100% health and decay when you miss days. The decay accelerates with consecutive misses, and recovery is faster at lower health.

## Features

- **Health decay model** — accelerating penalties for consecutive misses, inverse recovery on completions
- **Overflow banking** — extra logs buffer against future decay and display above 100%
- **Daily and weekly habits** — track "every day" or "X times per week"
- **Backfill** — swipe to open a drawer and log past days you missed marking
- **Drag to reorder** — long-press and drag to arrange habits
- **2am day boundary** — night owls get credit for late-night completions
- **Offline-first** — Firestore handles sync; works without connectivity
- **Google Sign-In** — data backed up to the cloud automatically

## How This Was Built

This project follows a documentation-first process. The full process is documented in [`docs/`](docs/):

| Document | Purpose |
|---|---|
| [Process](docs/01-process.md) | Development workflow and conventions |
| [PRD](docs/02-prd.md) | Product requirements and user stories |
| [Design Guide](docs/03-design-guide.md) | Visual design system and component specs |
| [System Design](docs/04-system-design.md) | Architecture, data model, and implementation phases |
| [Future](docs/05-future.md) | Deferred features and v2+ ideas |
| [Unit Tests](docs/06-testing-unit.md) | Unit test strategy and coverage |
| [Manual Tests](docs/07-testing-manual.md) | Manual test checklist |

## Tech Stack

- **Framework**: Flutter (Dart)
- **Auth**: Google Sign-In via Firebase Auth
- **Database**: Cloud Firestore (offline-first, real-time sync)
- **State Management**: Riverpod (StreamProviders for reactive UI)
- **UI**: Google Fonts (Inter), Material 3

## Development

```bash
flutter pub get              # Install dependencies
flutter run                  # Run on connected device/emulator
flutter test                 # Run unit tests
flutter analyze              # Lint check
flutter build apk --release  # Build release APK
```

### Sideloading

```bash
# Build and install via USB
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```
lib/
├── main.dart                # Entry point
├── app.dart                 # Auth routing (sign-in vs home)
├── models/                  # Habit, Log data classes
├── services/                # Firestore CRUD (habit_service, log_service)
├── providers/               # Riverpod providers (auth, habits, logs, health)
├── utils/                   # Decay algorithm, date helpers
├── screens/                 # sign_in_screen, home_screen
└── widgets/                 # Habit row, modals, backfill drawer, form fields
```

## License

[MIT](LICENSE)

---

Built w/ ❤️ by [Kyle Chadha](https://kylechadha.dev) · [@kylechadha](https://twitter.com/kylechadha)
