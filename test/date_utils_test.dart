// Unit tests for date utilities

import 'package:flutter_test/flutter_test.dart';
import 'package:smpl_tracker/utils/date_utils.dart';

void main() {
  group('formatDateForStorage', () {
    test('formats date correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(formatDateForStorage(date), '2024-01-15');
    });

    test('pads single digit month and day', () {
      final date = DateTime(2024, 3, 5);
      expect(formatDateForStorage(date), '2024-03-05');
    });
  });

  group('formatDisplayDate', () {
    test('formats date with weekday and month', () {
      final date = DateTime(2024, 1, 15); // Monday
      expect(formatDisplayDate(date), 'Monday, January 15');
    });
  });

  group('getWeekStart', () {
    test('returns Sunday for a Wednesday', () {
      final wednesday = DateTime(2024, 1, 10); // Wednesday Jan 10, 2024
      final weekStart = getWeekStart(wednesday);
      expect(weekStart.weekday, DateTime.sunday);
      expect(weekStart, DateTime(2024, 1, 7));
    });

    test('returns same day for Sunday', () {
      final sunday = DateTime(2024, 1, 7);
      final weekStart = getWeekStart(sunday);
      expect(weekStart, DateTime(2024, 1, 7));
    });

    test('handles month boundary correctly', () {
      // Feb 1, 2024 is Thursday, week started Jan 28
      final feb1 = DateTime(2024, 2, 1);
      final weekStart = getWeekStart(feb1);
      expect(weekStart, DateTime(2024, 1, 28));
    });
  });

  group('getWeekEnd', () {
    test('returns Saturday for a Wednesday', () {
      final wednesday = DateTime(2024, 1, 10);
      final weekEnd = getWeekEnd(wednesday);
      expect(weekEnd.weekday, DateTime.saturday);
      expect(weekEnd, DateTime(2024, 1, 13));
    });
  });
}
