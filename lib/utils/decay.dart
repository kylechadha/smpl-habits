import 'dart:math';
import '../models/habit.dart';
import '../models/log.dart';
import 'date_utils.dart';

/// Core parameters for health calculation
const int gracePeriodDaily = 1;
const double baseDecayRate = 5.0;
const double decayAcceleration = 1.5;
const double maxHealth = 150.0;
const double minHealth = 0.0;

/// Calculate the current health for a habit based on its logs
double calculateHealth(Habit habit, List<Log> logs) {
  // Create a set of logged dates for O(1) lookup
  final loggedDates = logs.map((l) => l.loggedDate).toSet();

  double health = 100.0;
  final today = getCurrentDay();
  final gracePeriod = habit.isDaily ? gracePeriodDaily : (7 / habit.frequencyCount).ceil();

  // Walk FORWARD through time (oldest to newest) over 90 days
  int consecutiveMisses = 0;

  for (int daysAgo = 89; daysAgo >= 0; daysAgo--) {
    final date = today.subtract(Duration(days: daysAgo));
    final dateStr = formatDateForStorage(date);
    final wasLogged = loggedDates.contains(dateStr);

    if (habit.isDaily) {
      // Daily habit: check each day
      if (wasLogged) {
        health = min(maxHealth, health + _recoveryAmount(health));
        consecutiveMisses = 0;
      } else if (daysAgo < 90 - gracePeriod) {
        // Only decay after grace period from start of tracking
        consecutiveMisses++;
        health = max(minHealth, health - _decayAmount(consecutiveMisses));
      }
    } else {
      // Weekly habit: check at end of each week
      final weekStart = getWeekStart(date);
      final weekEnd = getWeekEnd(date);

      // Only process on the last day of the week we're examining
      if (date == weekEnd || (daysAgo == 0 && date.isBefore(weekEnd))) {
        // Count logs for this week
        final weekStartStr = formatDateForStorage(weekStart);
        final weekEndStr = formatDateForStorage(weekEnd);
        final weekLogs = logs.where((log) =>
            log.loggedDate.compareTo(weekStartStr) >= 0 &&
            log.loggedDate.compareTo(weekEndStr) <= 0).length;

        if (weekLogs >= habit.frequencyCount) {
          // Met target - recover
          final overflowLogs = weekLogs - habit.frequencyCount;
          health = min(maxHealth, health + _recoveryAmount(health));
          // Extra logs add bonus recovery
          for (int i = 0; i < overflowLogs; i++) {
            health = min(maxHealth, health + _recoveryAmount(health) * 0.5);
          }
          consecutiveMisses = 0;
        } else if (daysAgo < 90 - gracePeriod * 7) {
          // Missed target - decay based on how short
          final missed = habit.frequencyCount - weekLogs;
          for (int i = 0; i < missed; i++) {
            consecutiveMisses++;
            health = max(minHealth, health - _decayAmount(consecutiveMisses) * 0.5);
          }
        }
      }
    }
  }

  return health;
}

/// Accelerating decay: 5%, 7.5%, 11.25%, ...
double _decayAmount(int consecutiveMisses) {
  return baseDecayRate * pow(decayAcceleration, consecutiveMisses - 1);
}

/// Recovery inversely proportional to current health
double _recoveryAmount(double currentHealth) {
  return baseDecayRate * (1 + (100 - currentHealth) / 100);
}
