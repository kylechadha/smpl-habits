# Unit Tests

Run all tests: `flutter test`

### Coverage

| File | Tests | What's covered |
|------|-------|----------------|
| `test/decay_test.dart` | 63 | Health decay algorithm: daily/weekly behavior, grace periods, recovery, overflow, edge cases, DST boundaries, Sunday boundary, RED tests for critical bugs, healthResetAt, rolling 7-day math |
| `test/date_utils_test.dart` | 1 | Date formatting, week start/end calculation, month boundaries |
| `test/widget_test.dart` | 1 | Sign-in screen renders correctly |
| **Total** | **65** | Core algorithm + date math + regression tests |

### Decay Algorithm Tests (63 tests)

The decay algorithm is the core game mechanic and has comprehensive coverage:

- **Daily habits** (5 tests): basic decay, grace period, accelerating decay, recovery proportional to health
- **Weekly habits** (15 tests): weekly evaluation, overflow bonus, partial week handling, grace period scaling, mid-week provisional decay
- **Edge cases** (8 tests): empty logs, logs outside 90-day window, duplicate logs, 7x/week habits, DST boundaries
- **Critical bug regressions** (3 RED tests): Sunday boundary condition, single log jump to 100%, health at 2/5 target
- **Internals** (3 tests): decay acceleration rate (1.1x gentle exponential), recovery curve formula, base rate values
- **Real data** (1 test): 7am Rise trace validation (Mar 8-14 scenario from production Firestore)
- **Grace period** (4 tests): new 5x/week at 100% on creation, stays 100% during grace, decays after, 3x/week has longer grace
- **healthResetAt** (3 tests): reset clears health to 100%, ignores logs before reset, decay starts from reset date
- **healthStartDate getter** (3 tests): returns createdAt when null, returns healthResetAt when set, algorithm uses it
- **DST safety** (3 tests): getWeekEnd/getWeekStart return midnight across DST spring-forward and fall-back
- **Rolling 7 days** (5 tests): month boundary, DST, year boundary, leap year, Duration vs DateTime constructor safety

### Adding Tests

The `calculateHealth` function accepts an optional `today` parameter for deterministic testing:
```dart
calculateHealth(habit, logs, today: DateTime(2024, 6, 15));
```

### Test Gaps (documented for future)

These areas aren't unit-testable (require widget/integration tests):
- Provider-level `isPaused` short-circuit (returns 100.0)
- Optimistic UI toggle and Firestore sync
- Slidable backfill drawer gesture interaction
- ReorderableListView drag handle reordering

See also: [Manual Testing](07-testing-manual.md)
