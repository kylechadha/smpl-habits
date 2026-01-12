import 'package:intl/intl.dart';

/// Get the current "day" respecting the 2am boundary.
/// If before 2 AM, it's still "yesterday".
/// Note: Dart's DateTime constructor handles day=0 correctly by
/// rolling back to the previous month (e.g., Jan 1 1am -> Dec 31).
DateTime getCurrentDay() {
  final now = DateTime.now();
  if (now.hour < 2) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return DateTime(now.year, now.month, now.day);
}

/// Format a date as YYYY-MM-DD for Firestore storage
String formatDateForStorage(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Format a date for display (e.g., "Saturday, January 11")
String formatDisplayDate(DateTime date) {
  return DateFormat('EEEE, MMMM d').format(date);
}

/// Get the start of the current week (Sunday)
DateTime getWeekStart(DateTime date) {
  final daysFromSunday = date.weekday % 7;
  return DateTime(date.year, date.month, date.day - daysFromSunday);
}

/// Get the end of the current week (Saturday)
DateTime getWeekEnd(DateTime date) {
  final weekStart = getWeekStart(date);
  return weekStart.add(const Duration(days: 6));
}
