import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log.dart';
import '../utils/date_utils.dart';

/// Service for habit log operations
class LogService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LogService(this.userId);

  CollectionReference<Map<String, dynamic>> get _logsCollection {
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  /// Watch all logs for a specific habit
  Stream<List<Log>> watchLogs(String habitId) {
    return _logsCollection
        .where('habit_id', isEqualTo: habitId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Log.fromFirestore).toList());
  }

  /// Toggle log for a specific habit and date (atomic transaction)
  /// Returns true if log was created, false if deleted
  Future<bool> toggleLog(String habitId, DateTime date) async {
    final dateStr = formatDateForStorage(date);
    final logId = Log.createId(habitId, dateStr);
    final docRef = _logsCollection.doc(logId);

    return _firestore.runTransaction<bool>((transaction) async {
      final doc = await transaction.get(docRef);
      if (doc.exists) {
        transaction.delete(docRef);
        return false;
      } else {
        transaction.set(docRef, {
          'habit_id': habitId,
          'logged_date': dateStr,
          'created_at': FieldValue.serverTimestamp(),
        });
        return true;
      }
    });
  }

  /// Check if a habit is logged for a specific date
  Future<bool> isLogged(String habitId, DateTime date) async {
    final dateStr = formatDateForStorage(date);
    final logId = Log.createId(habitId, dateStr);
    final doc = await _logsCollection.doc(logId).get();
    return doc.exists;
  }

  /// Get logs for a habit within a date range (for weekly counts, health calc)
  Future<List<Log>> getLogsInRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr = formatDateForStorage(startDate);
    final endStr = formatDateForStorage(endDate);

    final snapshot = await _logsCollection
        .where('habit_id', isEqualTo: habitId)
        .where('logged_date', isGreaterThanOrEqualTo: startStr)
        .where('logged_date', isLessThanOrEqualTo: endStr)
        .get();

    return snapshot.docs.map(Log.fromFirestore).toList();
  }

  /// Get count of logs for a habit in the current week
  Future<int> getWeeklyLogCount(String habitId) async {
    final today = getCurrentDay();
    final weekStart = getWeekStart(today);
    final weekEnd = getWeekEnd(today);

    final logs = await getLogsInRange(habitId, weekStart, weekEnd);
    return logs.length;
  }
}
