import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/logs_provider.dart';
import '../services/log_service.dart';
import '../utils/date_utils.dart';

/// 7-day backfill drawer showing in swipe action
class BackfillDrawer extends ConsumerWidget {
  final String habitId;

  const BackfillDrawer({
    super.key,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(habitLogsProvider(habitId));
    final logService = ref.watch(logServiceProvider);
    final today = getCurrentDay();

    // Get logged dates as set for quick lookup
    final loggedDates = logsAsync.when(
      data: (logs) => logs.map((l) => l.loggedDate).toSet(),
      loading: () => <String>{},
      error: (e, s) => <String>{},
    );

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 7 day checkboxes (most recent on right)
          for (int i = 6; i >= 0; i--) ...[
            _buildDayCheckbox(
              context,
              ref,
              today.subtract(Duration(days: i)),
              loggedDates,
              logService,
              isToday: i == 0,
            ),
            if (i > 0) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCheckbox(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    Set<String> loggedDates,
    LogService? logService, {
    required bool isToday,
  }) {
    final dateStr = formatDateForStorage(date);
    final isLogged = loggedDates.contains(dateStr);
    final dayLabel = _getDayLabel(date);

    return GestureDetector(
      onTap: () {
        if (logService != null) {
          logService.toggleLog(habitId, date);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLogged ? const Color(0xFF10B981) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLogged
                    ? const Color(0xFF10B981)
                    : isToday
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: isLogged
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }
}
