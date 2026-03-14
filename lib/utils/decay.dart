import 'dart:math';
import '../models/habit.dart';
import '../models/log.dart';
import 'date_utils.dart';

/// Core parameters for health calculation
const int gracePeriodDaily = 1;
const double baseDecayRate = 5.0;
const double decayAcceleration = 1.1;  // Gentle acceleration: 10% increase per consecutive miss
const double maxHealth = 100.0;
const double minHealth = 0.0;

/// Calculate the current health for a habit based on its logs.
/// [today] can be provided for testing; defaults to getCurrentDay().
double calculateHealth(Habit habit, List<Log> logs, {DateTime? today}) {
  // Create a set of logged dates for O(1) lookup
  final loggedDates = logs.map((l) => l.loggedDate).toSet();

  double health = 100.0;
  today ??= getCurrentDay();
  final gracePeriod = habit.isDaily ? gracePeriodDaily : (7 / habit.frequencyCount).ceil();
  final createdDay = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);

  // Walk FORWARD through time (oldest to newest) over 90 days
  int consecutiveMisses = 0;

  for (int daysAgo = 89; daysAgo >= 0; daysAgo--) {
    final date = today.subtract(Duration(days: daysAgo));
    // Normalize to midnight to avoid DST issues
    final dateMidnightNorm = DateTime(date.year, date.month, date.day);
    // Skip days before the habit was created
    if (dateMidnightNorm.isBefore(createdDay)) continue;
    final dateStr = formatDateForStorage(dateMidnightNorm);

    final wasLogged = loggedDates.contains(dateStr);
    final daysSinceCreation = date.difference(createdDay).inDays;

    if (habit.isDaily) {
      // Daily habit: check each day
      if (wasLogged) {
        health = min(maxHealth, health + _recoveryAmount(health));
        consecutiveMisses = 0;
      } else if (daysSinceCreation > gracePeriod) {
        // Only decay after grace period from creation
        consecutiveMisses++;
        health = max(minHealth, health - _decayAmount(consecutiveMisses));
      }
    } else {
      // Weekly habit: check at end of each week + mid-week provisional decay
      final weekStart = getWeekStart(dateMidnightNorm);
      final weekEnd = getWeekEnd(dateMidnightNorm);

      // Normalize to calendar dates (ignoring time) for comparison
      // This avoids DST bugs where subtract(Duration) can leave fractional hours
      final weekEndMidnight = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
      final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

      if (dateMidnightNorm == weekEndMidnight) {
        // Completed week: evaluate fully
        final weekStartStr = formatDateForStorage(weekStartMidnight);
        final weekEndStr = formatDateForStorage(weekEndMidnight);
        final weekLogs = logs.where((log) =>
            log.loggedDate.compareTo(weekStartStr) >= 0 &&
            log.loggedDate.compareTo(weekEndStr) <= 0).length;

        if (weekLogs >= habit.frequencyCount) {
          // Met target - recover (no bonus for extra logs)
          // Only recover after grace period
          if (daysSinceCreation > gracePeriod) {
            health = min(maxHealth, health + _recoveryAmount(health));
          }
          consecutiveMisses = 0;
        } else if (daysSinceCreation > gracePeriod) {
          // Missed target - decay based on how short
          final missed = habit.frequencyCount - weekLogs;
          for (int i = 0; i < missed; i++) {
            consecutiveMisses++;
            health = max(minHealth, health - _decayAmount(consecutiveMisses) * 0.5);
          }
        }
      } else if (daysAgo == 0 && (dateMidnightNorm == weekStartMidnight || dateMidnightNorm.isAfter(weekStartMidnight))) {
        // Current week (including Sunday): apply provisional mid-week penalty
        // Fixed: now includes Sunday (when date == weekStart) to ensure health updates continuously
        final weekStartStr = formatDateForStorage(weekStartMidnight);
        final todayStr = formatDateForStorage(dateMidnightNorm);
        final weekLogs = logs.where((log) =>
            log.loggedDate.compareTo(weekStartStr) >= 0 &&
            log.loggedDate.compareTo(todayStr) <= 0).length;

        if (weekLogs >= habit.frequencyCount) {
          // Already met target mid-week - recover
          // Only recover after grace period
          if (daysSinceCreation > gracePeriod) {
            health = min(maxHealth, health + _recoveryAmount(health));
          }
          consecutiveMisses = 0;
        } else {
          // Behind pace: apply small provisional penalty
          // Expected logs by now, proportional to how far through the week
          final daysElapsed = dateMidnightNorm.difference(weekStartMidnight).inDays + 1;
          final expectedLogs = habit.frequencyCount * daysElapsed / 7.0;
          final shortfall = (expectedLogs - weekLogs);

          if (shortfall > 0) {
            // Penalty proportional to shortfall — higher frequency = more expected
            // = larger shortfall = more decay. Scaled gently (0.15x base rate).
            final penalty = shortfall * baseDecayRate * 0.15;
            health = max(minHealth, health - penalty);
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
