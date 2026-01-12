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

  Habit({
    required this.id,
    required this.name,
    required this.frequencyType,
    required this.frequencyCount,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDaily => frequencyType == 'daily';
  bool get isWeekly => frequencyType == 'weekly';

  /// Create from Firestore document with null-safe parsing
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
    );
  }

  /// Convert to Firestore map for create
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'frequency_type': frequencyType,
      'frequency_count': frequencyCount,
      'sort_order': sortOrder,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with some fields updated
  Habit copyWith({
    String? id,
    String? name,
    String? frequencyType,
    int? frequencyCount,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyCount: frequencyCount ?? this.frequencyCount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
