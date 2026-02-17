import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';

/// Service for habit CRUD operations
class HabitService {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HabitService(this.userId);

  CollectionReference<Map<String, dynamic>> get _habitsCollection {
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  /// Watch all habits for the user, ordered by sort_order
  Stream<List<Habit>> watchHabits() {
    return _habitsCollection
        .orderBy('sort_order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Habit.fromFirestore).toList());
  }

  /// Create a new habit
  /// Note: sortOrder is not atomic; concurrent creates may collide but
  /// reorderHabits() can fix ordering. Acceptable for single-user app.
  Future<Habit> createHabit({
    required String name,
    required String frequencyType,
    required int frequencyCount,
  }) async {
    // Get current count for sort_order
    final snapshot = await _habitsCollection.get();
    final sortOrder = snapshot.docs.length;

    final now = DateTime.now();
    final docRef = await _habitsCollection.add({
      'name': name,
      'frequency_type': frequencyType,
      'frequency_count': frequencyCount,
      'sort_order': sortOrder,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });

    return Habit(
      id: docRef.id,
      name: name,
      frequencyType: frequencyType,
      frequencyCount: frequencyCount,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update an existing habit
  Future<void> updateHabit({
    required String habitId,
    String? name,
    String? frequencyType,
    int? frequencyCount,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (frequencyType != null) updates['frequency_type'] = frequencyType;
    if (frequencyCount != null) updates['frequency_count'] = frequencyCount;

    await _habitsCollection.doc(habitId).update(updates);
  }

  /// Delete a habit and all its logs (logs first to avoid orphans)
  Future<void> deleteHabit(String habitId) async {
    // Delete logs first to avoid orphaned data if interrupted
    final logsCollection =
        _firestore.collection('users').doc(userId).collection('logs');
    QuerySnapshot<Map<String, dynamic>> snapshot;
    do {
      snapshot = await logsCollection
          .where('habit_id', isEqualTo: habitId)
          .limit(500)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } while (snapshot.docs.isNotEmpty);

    // Then delete the habit
    await _habitsCollection.doc(habitId).delete();
  }

  /// Update sort order for multiple habits
  Future<void> reorderHabits(List<String> habitIds) async {
    final batch = _firestore.batch();

    for (int i = 0; i < habitIds.length; i++) {
      batch.update(_habitsCollection.doc(habitIds[i]), {
        'sort_order': i,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
