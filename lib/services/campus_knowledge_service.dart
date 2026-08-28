import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/campus_knowledge.dart';

class CampusKnowledgeService {
  static Future<String> _collegeId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to access campus knowledge.');
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('details')
        .get();
    final collegeId = profile.data()?['collegeId'] as String?;
    if (collegeId == null || collegeId.isEmpty) {
      throw StateError('Choose a college before accessing campus knowledge.');
    }
    return collegeId;
  }

  static Future<CollectionReference<Map<String, dynamic>>> _knowledge() async {
    final collegeId = await _collegeId();
    return FirebaseFirestore.instance
        .collection('colleges')
        .doc(collegeId)
        .collection('knowledge');
  }

  static Stream<List<CampusKnowledge>> watchKnowledge() async* {
    final collection = await _knowledge();
    yield* collection
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CampusKnowledge.fromDocument).toList());
  }

  static Future<String> addKnowledge({
    required String title,
    required String content,
    required String category,
    required List<String> sources,
    required bool isPublic,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to add campus knowledge.');
    final collection = await _knowledge();
    final reference = collection.doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(reference, {
      'title': title,
      'content': content,
      'category': category,
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email ?? 'Campus member',
      'verification': KnowledgeVerification.unverified.index,
      'trustScore': 0.5,
      'sources': sources,
      'isPublic': isPublic,
      'reportCount': 0,
      'hasConflict': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(reference.collection('history').doc(), {
      'type': 'created',
      'actorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return reference.id;
  }

  static Future<void> verify(CampusKnowledge knowledge) async {
    final collection = await _knowledge();
    await collection.doc(knowledge.id).update({
      'verification': KnowledgeVerification.communityVerified.index,
      'trustScore': 0.8,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> report(CampusKnowledge knowledge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to report knowledge.');
    final collection = await _knowledge();
    final report = collection.doc(knowledge.id).collection('reports').doc(user.uid);
    await report.set({
      'reporterId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await collection.doc(knowledge.id).update({
      'reportCount': FieldValue.increment(1),
      'hasConflict': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
