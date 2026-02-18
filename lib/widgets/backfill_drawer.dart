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

    final loggedDates = logsAsync.when(
      data: (logs) => logs.map((l) => l.loggedDate).toSet(),
      loading: () => <String>{},
      error: (e, s) => <String>{},
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 6; i >= 0; i--)
                _buildDayCheckbox(
                  today.subtract(Duration(days: i)),
                  loggedDates,
                  logService,
                  isToday: i == 0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCheckbox(
    DateTime date,
    Set<String> loggedDates,
    LogService? logService, {
    required bool isToday,
  }) {
    final dateStr = formatDateForStorage(date);
    final isLogged = loggedDates.contains(dateStr);
    final dayLabel = _getDayLabel(date);

    return GestureDetector(
      onTap: () => logService?.toggleLog(habitId, date),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isLogged
                  ? const Color(0xFF10B981)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLogged
                    ? const Color(0xFF10B981)
                    : isToday
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
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
