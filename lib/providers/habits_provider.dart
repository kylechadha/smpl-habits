import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'auth_provider.dart';

/// Provides a stream of the current user's habits
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return HabitService(user.uid).watchHabits();
    },
    loading: () => Stream.value([]),
    error: (e, s) => Stream.value([]),
  );
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
