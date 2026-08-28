import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CampusFeedService {
  static Future<CollectionReference<Map<String, dynamic>>> _posts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to access the campus feed.');
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('details')
        .get();
    final collegeId = profile.data()?['collegeId'] as String?;
    if (collegeId == null || collegeId.isEmpty) {
      throw StateError('Choose a college before accessing the campus feed.');
    }
    return FirebaseFirestore.instance
        .collection('colleges')
        .doc(collegeId)
        .collection('posts');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchPosts() async* {
    final posts = await _posts();
    yield* posts.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> addPost(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to publish a post.');
    final posts = await _posts();
    await posts.add({
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email ?? 'Campus member',
      'content': content,
      'reactionCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> react(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to react to a post.');
    final posts = await _posts();
    final reaction = posts.doc(postId).collection('reactions').doc(user.uid);
    final existing = await reaction.get();
    final batch = FirebaseFirestore.instance.batch();
    if (existing.exists) {
      batch.delete(reaction);
      batch.update(posts.doc(postId), {'reactionCount': FieldValue.increment(-1)});
    } else {
      batch.set(reaction, {'createdAt': FieldValue.serverTimestamp()});
      batch.update(posts.doc(postId), {'reactionCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  static Future<void> addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to comment on a post.');
    final posts = await _posts();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(posts.doc(postId).collection('comments').doc(), {
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email ?? 'Campus member',
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(posts.doc(postId), {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  static Future<Stream<QuerySnapshot<Map<String, dynamic>>>> comments(
    String postId,
  ) async {
    final posts = await _posts();
    return posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots();
  }
}
