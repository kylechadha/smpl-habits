import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../services/log_service.dart';
import '../utils/date_utils.dart';
import 'auth_provider.dart';

/// Provides the LogService for the current user
final logServiceProvider = Provider<LogService?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user != null ? LogService(user.uid) : null,
    loading: () => null,
    error: (e, s) => null,
  );
});

/// Optimistic overrides for today's log state, keyed by habitId.
/// null = no override (use Firestore stream). true/false = optimistic state.
final optimisticLogOverrideProvider =
    StateProvider<Map<String, bool>>((ref) => {});

/// Provides a stream of logs for a specific habit
final habitLogsProvider =
    StreamProvider.family<List<Log>, String>((ref, habitId) {
  final logService = ref.watch(logServiceProvider);
  if (logService == null) return Stream.value([]);
  return logService.watchLogs(habitId);
});

/// Check if a habit is logged today
final isLoggedTodayProvider = Provider.family<bool, String>((ref, habitId) {
  final overrides = ref.watch(optimisticLogOverrideProvider);
  final logsAsync = ref.watch(habitLogsProvider(habitId));
  final todayStr = formatDateForStorage(getCurrentDay());

  return logsAsync.when(
    data: (logs) {
      final firestoreValue = logs.any((log) => log.loggedDate == todayStr);
      // If override matches Firestore, clear it (sync confirmed)
      if (overrides.containsKey(habitId) &&
          overrides[habitId] == firestoreValue) {
        Future.microtask(() {
          ref.read(optimisticLogOverrideProvider.notifier).update(
            (state) => Map.of(state)..remove(habitId),
          );
        });
      }
      // Override takes precedence while active
      return overrides[habitId] ?? firestoreValue;
    },
    loading: () => overrides[habitId] ?? false,
    error: (e, s) => overrides[habitId] ?? false,
  );
});

/// Get weekly log count for a habit
final weeklyLogCountProvider = Provider.family<int, String>((ref, habitId) {
  final overrides = ref.watch(optimisticLogOverrideProvider);
  final logsAsync = ref.watch(habitLogsProvider(habitId));
  final today = getCurrentDay();
  final weekStart = getWeekStart(today);
  final weekEnd = getWeekEnd(today);
  final weekStartStr = formatDateForStorage(weekStart);
  final weekEndStr = formatDateForStorage(weekEnd);
  final todayStr = formatDateForStorage(today);

  return logsAsync.when(
    data: (logs) {
      int count = logs
          .where((log) =>
              log.loggedDate.compareTo(weekStartStr) >= 0 &&
              log.loggedDate.compareTo(weekEndStr) <= 0)
          .length;
      // Adjust count based on optimistic override for today
      if (overrides.containsKey(habitId)) {
        final todayInWeek = todayStr.compareTo(weekStartStr) >= 0 &&
            todayStr.compareTo(weekEndStr) <= 0;
        if (todayInWeek) {
          final wasLoggedInFirestore =
              logs.any((log) => log.loggedDate == todayStr);
          if (overrides[habitId]! && !wasLoggedInFirestore) count++;
          if (!overrides[habitId]! && wasLoggedInFirestore) count--;
        }
      }
      return count.clamp(0, 7);
    },
    loading: () => 0,
    error: (e, s) => 0,
  );
});
