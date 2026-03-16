import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/auth_provider.dart';
import '../providers/habits_provider.dart';
import '../providers/logs_provider.dart';
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
                          style: TextStyle(fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDisplayDate(getCurrentDay()),
                          style: TextStyle(fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Color(0xFF9CA3AF), size: 22),
                    onPressed: () => _showHelpBottomSheet(context),
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
                  // Wait for all habit log streams to have data before showing
                  final allLogsReady = habits.every((h) {
                    final logsAsync = ref.watch(habitLogsProvider(h.id));
                    return logsAsync.hasValue;
                  });
                  if (!allLogsReady) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
              style: TextStyle(fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first habit',
              style: TextStyle(fontFamily: 'Inter',
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

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How It Works',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),
              _buildHelpSection(
                title: 'Health',
                content: 'Habits start at 100% and decay when you miss targets. Logging rebuilds health.',
              ),
              _buildHelpSection(
                title: 'Recovery',
                content: 'Logging gives you: 5% + bonus when struggling. At 0% health, you recover 10%. At 100%, you recover 5%.',
              ),
              _buildHelpSection(
                title: 'Decay',
                content: 'Missing hurts more the longer you miss: 1st miss = 5%, 2nd miss = 5.5%, 3rd = 6.05%. Logging once resets the counter.',
              ),
              _buildHelpSection(
                title: 'Weekly Habits',
                content: 'You have 7 days to hit your target. Decay is softer (half strength) since you get the whole week. Saturday is final eval.',
              ),
              _buildHelpSection(
                title: 'Grace Period',
                content: 'New habits get 1-2 days before decay starts, so you have time to build momentum.',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
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
