# Unit Tests

Run all tests: `flutter test`

### Coverage

| File | Tests | What's covered |
|------|-------|----------------|
| `test/decay_test.dart` | 46 | Health decay algorithm: daily/weekly behavior, grace periods, recovery, overflow, edge cases, DST boundaries, Sunday boundary, RED tests for critical bugs |
| `test/date_utils_test.dart` | 1 | Date formatting, week start/end calculation, month boundaries |
| `test/widget_test.dart` | 1 | Sign-in screen renders correctly |
| **Total** | **48** | Complete coverage of core game mechanic and UI |

### Decay Algorithm Tests (46 tests)

The decay algorithm is the core game mechanic and has comprehensive coverage:

- **Daily habits** (5 tests): basic decay, grace period, accelerating decay, recovery proportional to health
- **Weekly habits** (15 tests): weekly evaluation, overflow bonus, partial week handling, grace period scaling, mid-week provisional decay
- **Edge cases** (8 tests): empty logs, logs outside 90-day window, duplicate logs, 7x/week habits, DST boundaries
- **Critical bug regressions** (3 RED tests): Sunday boundary condition, single log jump to 100%, health at 2/5 target
- **Internals** (3 tests): decay acceleration rate (1.1× gentle exponential), recovery curve formula, base rate values
- **Real data** (1 test): 7am Rise trace validation (Mar 8-14 scenario from production Firestore)

### Adding Tests

The `calculateHealth` function accepts an optional `today` parameter for deterministic testing:
```dart
calculateHealth(habit, logs, today: DateTime(2024, 6, 15));
```

See also: [Manual Testing](07-testing-manual.md)
