import 'package:cloud_firestore/cloud_firestore.dart';

class CampusPost {
  final String id;
  final String authorName;
  final String content;
  final DateTime? createdAt;
  final int reactionCount;
  final int commentCount;

  const CampusPost({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.reactionCount,
    required this.commentCount,
  });

  factory CampusPost.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CampusPost(
      id: doc.id,
      authorName: data['authorName'] as String? ?? 'Campus member',
      content: data['content'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reactionCount: data['reactionCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }
}
