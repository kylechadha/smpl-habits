# smpl-tracker

Simple habit tracker with decay-based motivation. Built with Flutter + Firebase, Android only.

## Features

- Track daily and weekly habits with a health decay model
- Health degrades on misses (accelerating), recovers on completions (inverse)
- Overflow banking — extra logs buffer against decay and display above 100%
- 2am day boundary for night owls
- Backfill past days via swipe drawer
- Drag to reorder habits
- Google Sign-In with Firestore backend (offline-first)

## Development

```bash
flutter pub get          # Install dependencies
flutter run              # Run on device/emulator
flutter test             # Run tests
flutter analyze          # Lint check
flutter build apk --release  # Release APK
```

## Sideloading

```bash
# Build release APK
flutter build apk --release

# Install via USB (with adb)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Or transfer the APK file to your phone and open it
# File is at: build/app/outputs/flutter-apk/app-release.apk
```

## License

MIT
