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

}
