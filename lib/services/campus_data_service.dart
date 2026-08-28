import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_item.dart';

class CampusDataService {
  static CollectionReference<Map<String, dynamic>> get _items {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access campus data.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items');
  }

  static Future<List<TaskItem>> loadItems() async {
    final snapshot = await _items.orderBy('createdAt').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TaskItem(
        id: doc.id,
        title: data['title'] as String? ?? 'Untitled',
        subtitle: data['subtitle'] as String? ?? '',
        category: data['category'] as String? ?? 'schedule',
        isCompleted: data['isCompleted'] as bool? ?? false,
      );
    }).toList();
  }

  static Future<void> saveItem(TaskItem item) {
    return _items.doc(item.id).set({
      'title': item.title,
      'subtitle': item.subtitle,
      'category': item.category,
      'isCompleted': item.isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteItem(String id) {
    return _items.doc(id).delete();
  }
}
