import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/campus_post.dart';
import '../services/campus_feed_service.dart';

class CampusFeedScreen extends StatefulWidget {
  const CampusFeedScreen({super.key});

  @override
  State<CampusFeedScreen> createState() => _CampusFeedScreenState();
}

class _CampusFeedScreenState extends State<CampusFeedScreen> {
  final _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;
    await CampusFeedService.addPost(content);
    _postController.clear();
  }

  void _openComments(CampusPost post) {
    final commentController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comments', style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<Stream<QuerySnapshot<Map<String, dynamic>>>>(
              future: CampusFeedService.comments(post.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: snapshot.data,
                  builder: (context, comments) => SizedBox(
                    height: 180,
                    child: ListView(
                      children: comments.data?.docs.map((doc) {
                            final data = doc.data();
                            return ListTile(
                              title: Text(data['authorName'] as String? ?? 'Member'),
                              subtitle: Text(data['content'] as String? ?? ''),
                            );
                          }).toList() ??
                          const [],
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final content = commentController.text.trim();
                    if (content.isEmpty) return;
                    await CampusFeedService.addComment(post.id, content);
                    commentController.clear();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(commentController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Feed')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: CampusFeedService.watchPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs.map(CampusPost.fromDocument).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _postController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Share a campus update...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _publish,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...posts.map(
                (post) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(post.content),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'React',
                              onPressed: () => CampusFeedService.react(post.id),
                              icon: const Icon(Icons.favorite_border),
                            ),
                            Text('${post.reactionCount}'),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => _openComments(post),
                              icon: const Icon(Icons.comment_outlined),
                              label: Text('${post.commentCount}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
