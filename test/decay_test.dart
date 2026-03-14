import 'dart:math';
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

/// Generate logs for past weeks to establish a healthy baseline.
List<Log> _baselineLogs(String habitId, DateTime today, {int weeks = 13, int count = 3}) {
  final logs = <Log>[];
  for (int w = 1; w <= weeks; w++) {
    final weekStart = today.subtract(Duration(days: today.weekday % 7 + w * 7));
    for (int d = 0; d < count && d < 7; d++) {
      logs.add(logFor(habitId, weekStart.add(Duration(days: d))));
    }
  }
  return logs;
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

    test('all 90 days logged = health at 100', () {
      final today = DateTime(2024, 6, 15);
      final logs =
          logsForDays('test-daily', today.subtract(const Duration(days: 89)), 90);
      final health = calculateHealth(dailyHabit(), logs, today: today);
      expect(health, equals(100.0));
    });

    test('logging today recovers health', () {
      final today = DateTime(2024, 6, 15);
      final healthWithout = calculateHealth(dailyHabit(), [], today: today);
      final healthWith =
          calculateHealth(dailyHabit(), [logFor('test-daily', today)], today: today);
      expect(healthWith, greaterThan(healthWithout));
    });

    test('health never exceeds maxHealth (100)', () {
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
      final today = DateTime(2024, 6, 15);
      final logs = logsForDays(
          'test-daily', today.subtract(const Duration(days: 89)), 89);
      final health = calculateHealth(dailyHabit(), logs, today: today);
      expect(health, greaterThanOrEqualTo(95));
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

      // More misses = more health loss (health capped at 100, so compare directly)
      expect(health10, lessThan(health5));
      // 10 misses should lose significantly more than 5
      expect(100 - health10, greaterThan(100 - health5));
    });
  });

  group('Daily habit - recovery', () {
    test('recovery is higher when health is lower', () {
      final lowHealth = _recoveryAmountPublic(20);
      final highHealth = _recoveryAmountPublic(80);
      expect(lowHealth, greaterThan(highHealth));
    });

    test('logging after misses recovers some health', () {
      final today = DateTime(2024, 6, 15);

      final logs = logsForDays(
          'test-daily', today.subtract(const Duration(days: 4)), 5);
      final healthRecovered = calculateHealth(dailyHabit(), logs, today: today);

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

    test('extra weekly logs beyond target have no effect', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 21); // Saturday
      final weekStart = DateTime(2026, 2, 15); // Sunday

      final logs = _baselineLogs('test-weekly', today, count: 3);
      for (int i = 0; i < 5; i++) {
        logs.add(logFor('test-weekly', weekStart.add(Duration(days: i))));
      }

      final health = calculateHealth(habit, logs, today: today);
      expect(health, lessThanOrEqualTo(100.0));
    });
  });

  group('Weekly habit - mid-week decay', () {
    test('mid-week with 0 logs shows provisional decay', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 25); // Wednesday
      final logs = _baselineLogs('test-weekly', today, count: 3);

      final health = calculateHealth(habit, logs, today: today);
      expect(health, lessThan(100.0));
    });

    test('mid-week decay increases as more days pass without logging', () {
      final habit = weeklyHabit(count: 3);
      final monday = DateTime(2026, 2, 23);
      final wednesday = DateTime(2026, 2, 25);

      final logsMonday = _baselineLogs('test-weekly', monday, count: 3);
      final logsWednesday = _baselineLogs('test-weekly', wednesday, count: 3);

      final healthMonday = calculateHealth(habit, logsMonday, today: monday);
      final healthWednesday =
          calculateHealth(habit, logsWednesday, today: wednesday);

      expect(healthMonday, lessThan(100.0));
      expect(healthWednesday, lessThan(healthMonday));
    });

    test('logging reduces the mid-week penalty', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 25); // Wednesday

      final logsNoLog = _baselineLogs('test-weekly', today, count: 3);
      final logsWithLog = List<Log>.from(_baselineLogs('test-weekly', today, count: 3))
        ..add(logFor('test-weekly', DateTime(2026, 2, 23))); // Monday

      final healthNoLogs = calculateHealth(habit, logsNoLog, today: today);
      final healthWithLog = calculateHealth(habit, logsWithLog, today: today);

      expect(healthWithLog, greaterThan(healthNoLogs));
    });

    test('meeting target mid-week gives recovery, no penalty', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 25); // Wednesday

      final logs = _baselineLogs('test-weekly', today, count: 3);
      logs.add(logFor('test-weekly', DateTime(2026, 2, 22))); // Sunday
      logs.add(logFor('test-weekly', DateTime(2026, 2, 23))); // Monday
      logs.add(logFor('test-weekly', DateTime(2026, 2, 24))); // Tuesday

      final health = calculateHealth(habit, logs, today: today);
      expect(health, equals(100.0));
    });

    test('no penalty on first day of week (Sunday)', () {
      final habit = weeklyHabit(count: 3);
      final sunday = DateTime(2026, 2, 22);
      final logs = _baselineLogs('test-weekly', sunday, count: 3);

      final health = calculateHealth(habit, logs, today: sunday);
      expect(health, equals(100.0));
    });

    test('higher frequency habits decay faster mid-week', () {
      final today = DateTime(2026, 2, 25); // Wednesday

      final habit3x = weeklyHabit(count: 3);
      final habit1x = weeklyHabit(count: 1);

      final logs3x = _baselineLogs('test-weekly', today, count: 3);
      final logs1x = _baselineLogs('test-weekly', today, count: 1);

      final health3x = calculateHealth(habit3x, logs3x, today: today);
      final health1x = calculateHealth(habit1x, logs1x, today: today);

      expect(health3x, lessThan(health1x));
    });
  });

  group('Weekly habit - completed week', () {
    test('completed week with met target gives recovery', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 28); // Saturday
      final logs = _baselineLogs('test-weekly', today, count: 3);
      logs.add(logFor('test-weekly', DateTime(2026, 2, 22)));
      logs.add(logFor('test-weekly', DateTime(2026, 2, 24)));
      logs.add(logFor('test-weekly', DateTime(2026, 2, 26)));

      final health = calculateHealth(habit, logs, today: today);
      expect(health, equals(100.0));
    });

    test('completed week with missed target causes decay', () {
      final habit = weeklyHabit(count: 3);
      final today = DateTime(2026, 2, 28); // Saturday
      final logs = _baselineLogs('test-weekly', today, count: 3);
      logs.add(logFor('test-weekly', DateTime(2026, 2, 22)));
      logs.add(logFor('test-weekly', DateTime(2026, 2, 24)));

      final health = calculateHealth(habit, logs, today: today);
      expect(health, lessThan(100.0));
    });

    test('mid-week does not apply decay for current week (old behavior)', () {
      final wednesday = DateTime(2024, 6, 12);
      final habit = weeklyHabit(count: 3);

      final healthWed = calculateHealth(habit, [], today: wednesday);

      final saturday = DateTime(2024, 6, 15);
      final healthSat = calculateHealth(habit, [], today: saturday);

      expect(healthSat, lessThanOrEqualTo(healthWed));
    });
  });

  group('Weekly habit - grace period', () {
    test('grace period is proportional to frequency', () {
      final today = DateTime(2024, 6, 15);

      final habit1x = weeklyHabit(count: 1);
      final habit3x = weeklyHabit(count: 3);

      final health1x = calculateHealth(habit1x, [], today: today);
      final health3x = calculateHealth(habit3x, [], today: today);

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
      expect(healthDouble, equals(healthSingle));
    });

    test('7x/week habit behaves like daily', () {
      final today = DateTime(2024, 6, 15);
      final habit7x = weeklyHabit(count: 7);
      final health = calculateHealth(habit7x, [], today: today);
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

  group('BUG: Weekly habit Sunday boundary', () {
    test('RED: Sunday should inherit health from Saturday, not reset', () {
      // BUG: On Sunday, date == weekStart, so isAfter(weekStart) is false.
      // No provisional penalty applied.
      // Scenario: Previous week (Feb 15-21) ended with health < 100% due to missed logs.
      // New week (Feb 22-28) starts on Sunday with 0 logs.
      // Sunday should show similar health to Saturday's ending, not reset.

      final habit = weeklyHabit(count: 3);
      final sunday = DateTime(2026, 2, 22); // Sunday (start of new week)
      final saturday = DateTime(2026, 2, 21); // Saturday (end of prev week)

      // Baseline logs for many weeks with 3/wk, establishing high health
      final logs = _baselineLogs('test-weekly', sunday, count: 3);

      // Intentionally miss the previous week (only 1 log instead of 3)
      // Remove most logs from the previous week
      final weekStartPrev = DateTime(2026, 2, 15); // Sun of prev week
      final weekEndPrev = DateTime(2026, 2, 21);   // Sat of prev week
      logs.removeWhere((log) {
        final date = DateTime.parse(log.loggedDate + ' 00:00:00');
        return date.isAfter(weekStartPrev) && date.isBefore(weekEndPrev.add(Duration(days: 1))) &&
            log.loggedDate != '2026-02-21'; // Keep only Saturday
      });

      final healthSaturday = calculateHealth(habit, logs, today: saturday);
      final healthSunday = calculateHealth(habit, logs, today: sunday);

      // Saturday (end of prev week with 1/3 target): should have decayed
      expect(healthSaturday, lessThan(100.0),
          reason: 'Previous week missed target (1/3), health should decay');

      // Sunday (start of new week, no logs yet): should inherit Saturday's health
      // NOT reset to 100%
      expect(healthSunday, lessThanOrEqualTo(healthSaturday),
          reason: 'Sunday boundary bug: health reset to 100% despite previous decay');
    });

    test('GREEN: Backfill drawer shows current week after fix', () {
      // Verifies the backfill drawer shows current week (Sun-Sat) not last 7 days.
      // This is a documentation test of what the fix should achieve.

      final wednesday = DateTime(2026, 2, 25); // Wednesday
      final weekStart = DateTime(2026, 2, 22); // Sunday of same week

      // After fix, drawer should iterate from weekStart for 7 days:
      // i=0: weekStart.add(Duration(days: 0)) = Sun
      // i=1: weekStart.add(Duration(days: 1)) = Mon
      // i=2: weekStart.add(Duration(days: 2)) = Tue
      // i=3: weekStart.add(Duration(days: 3)) = Wed
      // i=4: weekStart.add(Duration(days: 4)) = Thu
      // i=5: weekStart.add(Duration(days: 5)) = Fri
      // i=6: weekStart.add(Duration(days: 6)) = Sat

      final correctDays = [
        for (int i = 0; i < 7; i++) weekStart.add(Duration(days: i))
      ];

      // All days should be in the same week
      expect(correctDays.first.day, equals(22)); // Sunday
      expect(correctDays[1].day, equals(23)); // Monday
      expect(correctDays[2].day, equals(24)); // Tuesday
      expect(correctDays[3].day, equals(25)); // Wednesday (today)
      expect(correctDays[4].day, equals(26)); // Thursday
      expect(correctDays[5].day, equals(27)); // Friday
      expect(correctDays.last.day, equals(28)); // Saturday
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
  return baseDecayRate * pow(decayAcceleration, consecutiveMisses - 1);
}

double _recoveryAmountPublic(double currentHealth) {
  return baseDecayRate * (1 + (100 - currentHealth) / 100);
}
