import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a habit being tracked
class Habit {
  final String id;
  final String name;
  final String frequencyType; // "daily" or "weekly"
  final int frequencyCount; // 1 for daily, 1-7 for weekly
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? healthResetAt; // When set, health calc starts from this date
  final bool isPaused;

  Habit({
    required this.id,
    required this.name,
    required this.frequencyType,
    required this.frequencyCount,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.healthResetAt,
    this.isPaused = false,
  });

  bool get isDaily => frequencyType == 'daily';
  bool get isWeekly => frequencyType == 'weekly';

  /// The effective start date for health calculation
  DateTime get healthStartDate => healthResetAt ?? createdAt;

  factory Habit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Document ${doc.id} has no data');
    return Habit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      frequencyType: data['frequency_type'] as String? ?? 'daily',
      frequencyCount: data['frequency_count'] as int? ?? 1,
      sortOrder: data['sort_order'] as int? ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      healthResetAt: (data['health_reset_at'] as Timestamp?)?.toDate(),
      isPaused: data['is_paused'] as bool? ?? false,
    );
  }

}
