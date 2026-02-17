# Testing Strategy

## Unit Tests

Run all tests: `flutter test`

### Coverage

| File | Tests | What's covered |
|------|-------|----------------|
| `test/decay_test.dart` | 20 | Health decay algorithm: daily/weekly behavior, grace periods, recovery, overflow, edge cases, algorithm internals |
| `test/date_utils_test.dart` | 7 | Date formatting, week start/end calculation, month boundaries |
| `test/widget_test.dart` | 1 | Sign-in screen renders correctly |

### Decay Algorithm Tests

The decay algorithm is the core game mechanic and has the most coverage:

- **Daily habits**: basic decay, grace period, accelerating decay, recovery proportional to health
- **Weekly habits**: weekly evaluation, overflow bonus, partial week handling, grace period scaling
- **Edge cases**: empty logs, logs outside 90-day window, duplicate logs, 7x/week habits
- **Internals**: decay acceleration rate (geometric), recovery curve, base rate values

### Adding Tests

The `calculateHealth` function accepts an optional `today` parameter for deterministic testing:
```dart
calculateHealth(habit, logs, today: DateTime(2024, 6, 15));
```

## Manual Testing

### Emulator
- AVD: `smpl_tracker_test` (Pixel 7, API 34, google_apis_playstore ARM64)
- Boot: `emulator -avd smpl_tracker_test`
- Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

### Test Checklist
- [ ] Google Sign-In flow
- [ ] Sign out and re-sign-in
- [ ] Create daily habit
- [ ] Create weekly habit (3x/week)
- [ ] Toggle log (tap) - checkmark appears, health updates
- [ ] Un-toggle log - checkmark disappears
- [ ] Long-press to edit habit
- [ ] Delete habit from edit modal
- [ ] Swipe for backfill drawer
- [ ] Backfill past day checkbox
- [ ] Empty state when no habits
- [ ] FAB opens add habit modal
