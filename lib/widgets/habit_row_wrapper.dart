import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit.dart';
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
    final logService = ref.watch(logServiceProvider);

    return Slidable(
      key: ValueKey(habit.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.7,
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
        health: 100.0, // Implemented in Phase 4
        onTap: () {
          if (logService != null) {
            logService.toggleLog(habit.id, getCurrentDay());
          }
        },
        onLongPress: onLongPress,
      ),
    );
  }
}
