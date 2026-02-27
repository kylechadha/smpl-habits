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
class HabitRowWrapper extends ConsumerStatefulWidget {
  final Habit habit;
  final VoidCallback? onLongPress;

  const HabitRowWrapper({
    super.key,
    required this.habit,
    this.onLongPress,
  });

  @override
  ConsumerState<HabitRowWrapper> createState() => _HabitRowWrapperState();
}

class _HabitRowWrapperState extends ConsumerState<HabitRowWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedToday = ref.watch(isLoggedTodayProvider(widget.habit.id));
    final weeklyLogsCount =
        ref.watch(weeklyLogCountProvider(widget.habit.id));
    final health = ref.watch(habitHealthProvider(widget.habit));
    final logService = ref.watch(logServiceProvider);

    return Slidable(
      key: ValueKey(widget.habit.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 1.0,
        openThreshold: 0.15,
        closeThreshold: 0.15,
        children: [
          Expanded(
            child: BackfillDrawer(habitId: widget.habit.id),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: HabitRow(
          habit: widget.habit,
          isLoggedToday: isLoggedToday,
          weeklyLogsCount: weeklyLogsCount,
          health: health,
          onTap: () {
            if (logService != null) {
              final wasLogged = isLoggedToday;
              final newState = !wasLogged;

              // Haptic + animation on toggle ON
              if (!wasLogged) {
                HapticFeedback.mediumImpact();
                _animController.forward(from: 0);
              }

              // Optimistic UI: update immediately
              ref.read(optimisticLogOverrideProvider.notifier).update(
                (state) => {...state, widget.habit.id: newState},
              );
              // Fire Firestore write (queues if offline)
              logService
                  .toggleLog(widget.habit.id, getCurrentDay())
                  .catchError((_) {
                // Revert on error
                ref.read(optimisticLogOverrideProvider.notifier).update(
                  (state) => Map.of(state)..remove(widget.habit.id),
                );
                return false;
              });
            }
          },
          onLongPress: widget.onLongPress,
        ),
      ),
    );
  }
}
