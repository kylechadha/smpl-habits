import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit.dart';
import '../providers/health_provider.dart';
import '../providers/logs_provider.dart';
import '../utils/date_utils.dart';
import 'habit_row.dart';
import 'backfill_drawer.dart';

/// Wrapper that provides log state to HabitRow with slidable backfill drawer
class HabitRowWrapper extends ConsumerWidget {
  final Habit habit;
  final VoidCallback? onLongPress;

  const HabitRowWrapper({
    super.key,
    required this.habit,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedToday = ref.watch(isLoggedTodayProvider(habit.id));
    final weeklyLogsCount = ref.watch(weeklyLogCountProvider(habit.id));
    final health = ref.watch(habitHealthProvider(habit));
    final logService = ref.watch(logServiceProvider);

    return Slidable(
      key: ValueKey(habit.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 1.0,
        openThreshold: 0.15,
        closeThreshold: 0.15,
        children: [
          Expanded(
            child: BackfillDrawer(habitId: habit.id),
          ),
        ],
      ),
      child: HabitRow(
        habit: habit,
        isLoggedToday: isLoggedToday,
        weeklyLogsCount: weeklyLogsCount,
        health: health,
        onTap: () {
          HapticFeedback.lightImpact();
          logService?.toggleLog(habit.id, getCurrentDay());
        },
        onLongPress: onLongPress,
      ),
    );
  }
}
