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

/// Provides a stream of logs for a specific habit
final habitLogsProvider =
    StreamProvider.family<List<Log>, String>((ref, habitId) {
  final logService = ref.watch(logServiceProvider);
  if (logService == null) return Stream.value([]);
  return logService.watchLogs(habitId);
});

/// Check if a habit is logged today
final isLoggedTodayProvider = Provider.family<bool, String>((ref, habitId) {
  final logsAsync = ref.watch(habitLogsProvider(habitId));
  final todayStr = formatDateForStorage(getCurrentDay());

  return logsAsync.when(
    data: (logs) => logs.any((log) => log.loggedDate == todayStr),
    loading: () => false,
    error: (e, s) => false,
  );
});

/// Get weekly log count for a habit
final weeklyLogCountProvider = Provider.family<int, String>((ref, habitId) {
  final logsAsync = ref.watch(habitLogsProvider(habitId));
  final today = getCurrentDay();
  final weekStart = getWeekStart(today);
  final weekEnd = getWeekEnd(today);
  final weekStartStr = formatDateForStorage(weekStart);
  final weekEndStr = formatDateForStorage(weekEnd);

  return logsAsync.when(
    data: (logs) => logs
        .where((log) =>
            log.loggedDate.compareTo(weekStartStr) >= 0 &&
            log.loggedDate.compareTo(weekEndStr) <= 0)
        .length,
    loading: () => 0,
    error: (e, s) => 0,
  );
});
