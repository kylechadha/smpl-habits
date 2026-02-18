import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';

/// A single habit card showing name and health bar
class HabitRow extends StatelessWidget {
  final Habit habit;
  final bool isLoggedToday;
  final int weeklyLogsCount;
  final double health;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const HabitRow({
    super.key,
    required this.habit,
    required this.isLoggedToday,
    required this.weeklyLogsCount,
    required this.health,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLoggedToday) ...[
                      _buildCheckmark(),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        habit.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (habit.isWeekly) _buildWeeklyPips(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthBar(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${health.round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _getHealthColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF10B981),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildWeeklyPips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < habit.frequencyCount; i++) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i < weeklyLogsCount
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
          ),
          if (i < habit.frequencyCount - 1) const SizedBox(width: 4),
        ],
        const SizedBox(width: 6),
        Text(
          '$weeklyLogsCount/${habit.frequencyCount}',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthBar() {
    final fillWidth = (health.clamp(0.0, 150.0) / 100).clamp(0.0, 1.0);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fillWidth,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getHealthGradient(),
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: health > 100
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Color _getHealthColor() {
    if (health >= 100) return const Color(0xFF3B82F6); // Blue - overflow
    if (health >= 70) return const Color(0xFF10B981); // Green - healthy
    if (health >= 40) return const Color(0xFFF59E0B); // Yellow - warning
    return const Color(0xFFEF4444); // Red - critical
  }

  List<Color> _getHealthGradient() {
    if (health >= 100) {
      return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]; // Blue
    }
    if (health >= 70) {
      return [const Color(0xFF10B981), const Color(0xFF34D399)]; // Green
    }
    if (health >= 40) {
      return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]; // Yellow
    }
    return [const Color(0xFFEF4444), const Color(0xFFF87171)]; // Red
  }
}
