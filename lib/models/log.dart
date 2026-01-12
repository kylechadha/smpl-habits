import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single log entry for a habit on a specific date
/// Document ID format: {habitId}_{YYYY-MM-DD}
class Log {
  final String id;
  final String habitId;
  final String loggedDate; // YYYY-MM-DD format
  final DateTime createdAt;

  Log({
    required this.id,
    required this.habitId,
    required this.loggedDate,
    required this.createdAt,
  });

  /// Create composite document ID from habit ID and date
  static String createId(String habitId, String date) {
    return '${habitId}_$date';
  }

  /// Create from Firestore document with null-safe parsing
  factory Log.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Document ${doc.id} has no data');
    return Log(
      id: doc.id,
      habitId: data['habit_id'] as String? ?? '',
      loggedDate: data['logged_date'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map for create
  Map<String, dynamic> toFirestore() {
    return {
      'habit_id': habitId,
      'logged_date': loggedDate,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
