import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../providers/auth_provider.dart';
import '../providers/habits_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/habit_row_wrapper.dart';
import '../widgets/add_habit_modal.dart';
import '../widgets/edit_habit_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habits',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDisplayDate(getCurrentDay()),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF9CA3AF), size: 22),
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildHabitList(context, ref, habits);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading habits: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showAddHabitModal(context),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: const _FabLocation(),
    );
  }

  Widget _buildEmptyState() {
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first habit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitList(BuildContext context, WidgetRef ref, List<Habit> habits) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: habits.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Material(
            elevation: 4,
            color: Colors.transparent,
            shadowColor: Colors.black26,
            child: child,
          ),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<Habit>.from(habits);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        ref.read(habitServiceProvider)?.reorderHabits(
          reordered.map((h) => h.id).toList(),
        );
      },
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitRowWrapper(
          key: ValueKey(habit.id),
          habit: habit,
          onLongPress: () => showEditHabitModal(context, habit),
        );
      },
    );
  }
}

/// Positions the FAB to align with card content (12px margin + 16px padding = 28px from edge)
class _FabLocation extends FloatingActionButtonLocation {
  const _FabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double x = scaffoldGeometry.scaffoldSize.width - 56 - 20;
    final double y = scaffoldGeometry.scaffoldSize.height - 56 - 70;
    return Offset(x, y);
  }
}
