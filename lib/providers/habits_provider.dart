import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'auth_provider.dart';

/// Provides a stream of the current user's habits
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final service = ref.watch(habitServiceProvider);
  if (service == null) return Stream.value([]);
  return service.watchHabits();
});

/// Provides the HabitService for the current user
final habitServiceProvider = Provider<HabitService?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user != null ? HabitService(user.uid) : null,
    loading: () => null,
    error: (e, s) => null,
  );
});
