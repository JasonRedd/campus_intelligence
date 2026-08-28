import 'package:cloud_firestore/cloud_firestore.dart';

enum KnowledgeVerification { unverified, communityVerified, staffVerified }

class CampusKnowledge {
  final String id;
  final String title;
  final String content;
  final String category;
  final String authorId;
  final String authorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final KnowledgeVerification verification;
  final double trustScore;
  final List<String> sources;
  final bool isPublic;
  final int reportCount;
  final bool hasConflict;

  const CampusKnowledge({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    required this.verification,
    required this.trustScore,
    required this.sources,
    required this.isPublic,
    required this.reportCount,
    required this.hasConflict,
  });

  factory CampusKnowledge.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return CampusKnowledge(
      id: document.id,
      title: data['title'] as String? ?? 'Untitled',
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Campus member',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      verification: KnowledgeVerification.values[
          (data['verification'] as int? ?? 0).clamp(0, 2)],
      trustScore: (data['trustScore'] as num? ?? 0).toDouble(),
      sources: List<String>.from(data['sources'] as List? ?? const []),
      isPublic: data['isPublic'] as bool? ?? true,
      reportCount: data['reportCount'] as int? ?? 0,
      hasConflict: data['hasConflict'] as bool? ?? false,
    );
  }
}
