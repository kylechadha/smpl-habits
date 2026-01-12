import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../utils/decay.dart';
import 'logs_provider.dart';

/// Provides calculated health for a specific habit
final habitHealthProvider = Provider.family<double, Habit>((ref, habit) {
  final logsAsync = ref.watch(habitLogsProvider(habit.id));

  return logsAsync.when(
    data: (logs) => calculateHealth(habit, logs),
    loading: () => 100.0, // Default while loading
    error: (e, s) => 100.0, // Default on error
  );
});
