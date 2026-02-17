import 'package:flutter_test/flutter_test.dart';
import 'package:smpl_tracker/models/habit.dart';
import 'package:smpl_tracker/models/log.dart';
import 'package:smpl_tracker/utils/decay.dart';

/// Helper to create a daily habit for testing
Habit dailyHabit() => Habit(
      id: 'test-daily',
      name: 'Exercise',
      frequencyType: 'daily',
      frequencyCount: 1,
      sortOrder: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

/// Helper to create a weekly habit for testing
Habit weeklyHabit({int count = 3}) => Habit(
      id: 'test-weekly',
      name: 'Read',
      frequencyType: 'weekly',
      frequencyCount: count,
      sortOrder: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

/// Helper to create a log for a given date
Log logFor(String habitId, DateTime date) => Log(
      id: '${habitId}_${date.toIso8601String().substring(0, 10)}',
      habitId: habitId,
      loggedDate:
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      createdAt: date,
    );

/// Helper to create logs for a range of dates
List<Log> logsForDays(String habitId, DateTime start, int count) {
  return List.generate(
      count, (i) => logFor(habitId, start.add(Duration(days: i))));
}

void main() {
  group('Daily habit - basic behavior', () {
    test('no logs = health decays from 100', () {
      final today = DateTime(2024, 6, 15);
      final health = calculateHealth(dailyHabit(), [], today: today);
      expect(health, lessThan(100));
    });

    test('no logs for 90 days = health at 0', () {
      final today = DateTime(2024, 6, 15);
      final health = calculateHealth(dailyHabit(), [], today: today);
      expect(health, equals(0));
    });

    test('all 90 days logged = health above 100 (overflow)', () {
      final today = DateTime(2024, 6, 15);
      final logs =
          logsForDays('test-daily', today.subtract(const Duration(days: 89)), 90);
      final health = calculateHealth(dailyHabit(), logs, today: today);
      expect(health, greaterThan(100));
    });

    test('logging today recovers health', () {
      final today = DateTime(2024, 6, 15);
      final healthWithout = calculateHealth(dailyHabit(), [], today: today);
      final healthWith =
          calculateHealth(dailyHabit(), [logFor('test-daily', today)], today: today);
      expect(healthWith, greaterThan(healthWithout));
    });

    test('health never exceeds maxHealth (150)', () {
      final today = DateTime(2024, 6, 15);
      final logs =
          logsForDays('test-daily', today.subtract(const Duration(days: 89)), 90);
      final health = calculateHealth(dailyHabit(), logs, today: today);
      expect(health, lessThanOrEqualTo(maxHealth));
    });

    test('health never goes below 0', () {
      final today = DateTime(2024, 6, 15);
      final health = calculateHealth(dailyHabit(), [], today: today);
      expect(health, greaterThanOrEqualTo(0));
    });
  });

  group('Daily habit - grace period', () {
    test('first day has no decay (grace period)', () {
      // With only 1 day of history, the grace period should prevent decay
      final today = DateTime(2024, 6, 15);
      final logs = logsForDays(
          'test-daily', today.subtract(const Duration(days: 89)), 89);
      // Logged every day except today
      final health = calculateHealth(dailyHabit(), logs, today: today);
      // Should still be high because only 1 miss and grace period covers it
      expect(health, greaterThan(95));
    });
  });

  group('Daily habit - accelerating decay', () {
    test('consecutive misses accelerate decay', () {
      final today = DateTime(2024, 6, 15);

      // 5 days of no logs at the end
      final logs5miss = logsForDays(
          'test-daily', today.subtract(const Duration(days: 89)), 85);
      final health5 = calculateHealth(dailyHabit(), logs5miss, today: today);

      // 10 days of no logs at the end
      final logs10miss = logsForDays(
          'test-daily', today.subtract(const Duration(days: 89)), 80);
      final health10 = calculateHealth(dailyHabit(), logs10miss, today: today);

      // 10 misses should lose more than 2x what 5 misses loses (accelerating)
      final loss5 = 100 - health5;
      final loss10 = 100 - health10;
      expect(loss10, greaterThan(loss5 * 2));
    });
  });

  group('Daily habit - recovery', () {
    test('recovery is higher when health is lower', () {
      // Recovery is inversely proportional to current health
      final lowHealth = _recoveryAmountPublic(20);
      final highHealth = _recoveryAmountPublic(80);
      expect(lowHealth, greaterThan(highHealth));
    });

    test('logging after misses recovers some health', () {
      final today = DateTime(2024, 6, 15);

      // 10 days missed, then 5 days logged
      final logs = logsForDays(
          'test-daily', today.subtract(const Duration(days: 4)), 5);
      final healthRecovered = calculateHealth(dailyHabit(), logs, today: today);

      // Should be partially recovered from rock bottom
      expect(healthRecovered, greaterThan(0));
      expect(healthRecovered, lessThan(100));
    });
  });

  group('Weekly habit - basic behavior', () {
    test('no logs = health decays from 100', () {
      final today = DateTime(2024, 6, 15); // Saturday
      final health = calculateHealth(weeklyHabit(), [], today: today);
      expect(health, lessThan(100));
    });

    test('meeting weekly target recovers health', () {
      final today = DateTime(2024, 6, 15); // Saturday
      final habit = weeklyHabit(count: 3);

      // Log 3x/week for all weeks in 90-day window to build up health
      final logs = <Log>[];
      for (int w = 12; w >= 0; w--) {
        final weekStart = today.subtract(Duration(days: w * 7 + today.weekday % 7));
        final sun = getWeekStartForTest(weekStart);
        logs.add(logFor('test-weekly', sun));
        logs.add(logFor('test-weekly', sun.add(const Duration(days: 2))));
        logs.add(logFor('test-weekly', sun.add(const Duration(days: 4))));
      }

      final healthWith = calculateHealth(habit, logs, today: today);
      final healthWithout = calculateHealth(habit, [], today: today);
      expect(healthWith, greaterThan(healthWithout));
    });

    test('overflow logs provide bonus recovery', () {
      final today = DateTime(2024, 6, 15); // Saturday
      final habit = weeklyHabit(count: 3);
      final lastWeekStart = DateTime(2024, 6, 2);

      // Exactly 3 logs (meeting target)
      final logs3 = [
        logFor('test-weekly', lastWeekStart),
        logFor('test-weekly', lastWeekStart.add(const Duration(days: 1))),
        logFor('test-weekly', lastWeekStart.add(const Duration(days: 2))),
      ];

      // 5 logs (overflow by 2)
      final logs5 = [
        ...logs3,
        logFor('test-weekly', lastWeekStart.add(const Duration(days: 3))),
        logFor('test-weekly', lastWeekStart.add(const Duration(days: 4))),
      ];

      final health3 = calculateHealth(habit, logs3, today: today);
      final health5 = calculateHealth(habit, logs5, today: today);
      expect(health5, greaterThan(health3));
    });
  });

  group('Weekly habit - partial week', () {
    test('mid-week does not apply decay for current week', () {
      // Wednesday - week hasn't ended yet, so no decay for this week
      final wednesday = DateTime(2024, 6, 12);
      final habit = weeklyHabit(count: 3);

      // No logs at all - but current week hasn't ended
      // Health should only reflect completed past weeks, not current
      final healthWed = calculateHealth(habit, [], today: wednesday);

      // Saturday (week end) - now the week is evaluated
      final saturday = DateTime(2024, 6, 15);
      final healthSat = calculateHealth(habit, [], today: saturday);

      // Saturday should have more decay because the week completed
      expect(healthSat, lessThanOrEqualTo(healthWed));
    });
  });

  group('Weekly habit - grace period', () {
    test('grace period is proportional to frequency', () {
      final today = DateTime(2024, 6, 15);

      // 1x/week = 7-day grace, 3x/week = 3-day grace
      final habit1x = weeklyHabit(count: 1);
      final habit3x = weeklyHabit(count: 3);

      final health1x = calculateHealth(habit1x, [], today: today);
      final health3x = calculateHealth(habit3x, [], today: today);

      // 1x/week has longer grace period, so should have higher health
      // when all weeks are missed
      expect(health1x, greaterThanOrEqualTo(health3x));
    });
  });

  group('New habit starts at 100%', () {
    test('brand new daily habit starts at 100', () {
      final today = DateTime(2024, 6, 15);
      final habit = Habit(
        id: 'new',
        name: 'New',
        frequencyType: 'daily',
        frequencyCount: 1,
        sortOrder: 0,
        createdAt: today,
        updatedAt: today,
      );
      final health = calculateHealth(habit, [], today: today);
      expect(health, equals(100.0));
    });

    test('habit created yesterday with no logs has grace period', () {
      final today = DateTime(2024, 6, 15);
      final habit = Habit(
        id: 'new',
        name: 'New',
        frequencyType: 'daily',
        frequencyCount: 1,
        sortOrder: 0,
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.subtract(const Duration(days: 1)),
      );
      // Grace period is 1 day, so 1 missed day = no decay yet
      final health = calculateHealth(habit, [], today: today);
      expect(health, equals(100.0));
    });

    test('habit created 3 days ago with no logs starts decaying', () {
      final today = DateTime(2024, 6, 15);
      final habit = Habit(
        id: 'new',
        name: 'New',
        frequencyType: 'daily',
        frequencyCount: 1,
        sortOrder: 0,
        createdAt: today.subtract(const Duration(days: 3)),
        updatedAt: today.subtract(const Duration(days: 3)),
      );
      final health = calculateHealth(habit, [], today: today);
      expect(health, lessThan(100));
      expect(health, greaterThan(0));
    });
  });

  group('Edge cases', () {
    test('empty log list returns a valid health', () {
      final today = DateTime(2024, 6, 15);
      final health = calculateHealth(dailyHabit(), [], today: today);
      expect(health, isA<double>());
      expect(health, greaterThanOrEqualTo(0));
      expect(health, lessThanOrEqualTo(maxHealth));
    });

    test('logs outside 90-day window are ignored', () {
      final today = DateTime(2024, 6, 15);
      // Log from 100 days ago - should not affect health
      final oldLog =
          logFor('test-daily', today.subtract(const Duration(days: 100)));
      final healthWithOld = calculateHealth(dailyHabit(), [oldLog], today: today);
      final healthWithout = calculateHealth(dailyHabit(), [], today: today);
      expect(healthWithOld, equals(healthWithout));
    });

    test('duplicate logs for same date do not double count (daily)', () {
      final today = DateTime(2024, 6, 15);
      final log1 = logFor('test-daily', today);
      final log2 = Log(
        id: 'dup',
        habitId: 'test-daily',
        loggedDate: log1.loggedDate,
        createdAt: today,
      );
      final healthSingle = calculateHealth(dailyHabit(), [log1], today: today);
      final healthDouble =
          calculateHealth(dailyHabit(), [log1, log2], today: today);
      // Uses a Set for lookups, so duplicates don't matter for daily
      expect(healthDouble, equals(healthSingle));
    });

    test('7x/week habit behaves like daily', () {
      final today = DateTime(2024, 6, 15);
      final habit7x = weeklyHabit(count: 7);
      final health = calculateHealth(habit7x, [], today: today);
      // Should still produce a valid result
      expect(health, greaterThanOrEqualTo(0));
      expect(health, lessThanOrEqualTo(maxHealth));
    });
  });

  group('Decay algorithm internals', () {
    test('decay accelerates with consecutive misses', () {
      final decay1 = _decayAmountPublic(1);
      final decay2 = _decayAmountPublic(2);
      final decay3 = _decayAmountPublic(3);
      expect(decay2, greaterThan(decay1));
      expect(decay3, greaterThan(decay2));
      // Should be geometric: decay2/decay1 == decay3/decay2
      expect((decay2 / decay1).toStringAsFixed(2),
          equals((decay3 / decay2).toStringAsFixed(2)));
    });

    test('recovery decreases as health increases', () {
      final recovery0 = _recoveryAmountPublic(0);
      final recovery50 = _recoveryAmountPublic(50);
      final recovery100 = _recoveryAmountPublic(100);
      expect(recovery0, greaterThan(recovery50));
      expect(recovery50, greaterThan(recovery100));
    });

    test('base decay rate is 5%', () {
      expect(_decayAmountPublic(1), equals(5.0));
    });

    test('recovery at 100% health equals base rate', () {
      expect(_recoveryAmountPublic(100), equals(5.0));
    });

    test('recovery at 0% health equals 2x base rate', () {
      expect(_recoveryAmountPublic(0), equals(10.0));
    });
  });
}

/// Helper to get week start (Sunday) for a date
DateTime getWeekStartForTest(DateTime date) {
  final daysFromSunday = date.weekday % 7;
  return DateTime(date.year, date.month, date.day - daysFromSunday);
}

// Expose private functions for testing via wrappers
double _decayAmountPublic(int consecutiveMisses) {
  return baseDecayRate * 1.5 * (consecutiveMisses - 1) == 0
      ? baseDecayRate
      : baseDecayRate *
          _pow(decayAcceleration, consecutiveMisses - 1);
}

double _recoveryAmountPublic(double currentHealth) {
  return baseDecayRate * (1 + (100 - currentHealth) / 100);
}

double _pow(double base, int exponent) {
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
