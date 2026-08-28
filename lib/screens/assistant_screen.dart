import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _messageStream;
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMimeType;

  String _apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _messageStream = _messagesQuery(uid).snapshots();
    }
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats');
  }

  Query<Map<String, dynamic>> _messagesQuery(String uid) {
    return _messagesCollection(uid).orderBy('timestamp');
  }

  Future<String?> _uploadImage(Uint8List bytes, String mimeType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final ref = FirebaseStorage.instance.ref().child(
      'users/$uid/chat_images/${DateTime.now().microsecondsSinceEpoch}',
    );
    final metadata = SettableMetadata(contentType: mimeType);
    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  Future<void> _saveMessage({
    required String text,
    required bool isUser,
    String? imageUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _messagesCollection(uid).add({
      'text': text,
      'isUser': isUser,
      ...?imageUrl == null ? null : {'imageUrl': imageUrl},
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageMimeType = _mimeTypeFor(image.name);
    });
  }

  String _mimeTypeFor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageMimeType = null;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final imageBytes = _selectedImageBytes;
    final imageMimeType = _selectedImageMimeType;
    final prompt = text.isEmpty ? 'What is shown in this image?' : text;
    _messageController.clear();
    _clearSelectedImage();

    setState(() {
      _messages.add(
        ChatMessage(
          text: prompt,
          isUser: true,
          timestamp: DateTime.now(),
          imageBytes: imageBytes,
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final imageUrl = imageBytes == null
          ? null
          : await _uploadImage(imageBytes, imageMimeType ?? 'image/jpeg');
      await _saveMessage(text: prompt, isUser: true, imageUrl: imageUrl);
      final responseText = await _callGeminiApi(
        prompt,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );
      await _saveMessage(text: responseText, isUser: false);
    } catch (e) {
      await _saveMessage(text: 'Connection Error: $e', isUser: false);
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<String> _callGeminiApi(
    String prompt, {
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    if (_apiKey.trim().isEmpty) {
      final key = await _requestApiKey();
      if (key == null || key.trim().isEmpty) {
        return 'Assistant is not configured. Add a Gemini API key to continue.';
      }
      _apiKey = key.trim();
    }

    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    };

    final parts = <Map<String, dynamic>>[];
    if (imageBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': imageMimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }
    parts.add({'text': prompt});

    final Map<String, dynamic> body = {
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Campus AI, an intelligent and friendly assistant for '
                'university students. You are part of the Campus Intelligence '
                'app. Assist with timetables, coursework, campus logistics, '
                'and study materials. Keep answers concise, helpful, and '
                'formatted clearly. Never identify yourself as Gemini or '
                'Google Gemini.',
          },
        ],
      },
      'contents': [
        {'parts': parts},
      ],
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String? reply =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return reply ?? 'No text generated.';
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final String errorMessage =
            errorData['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return 'API Error (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      return 'Network Error: $e';
    }
  }

  Future<String?> _requestApiKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Campus Assistant'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Gemini API key',
            hintText: 'Paste your key here',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Use key'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: _buildProfileDrawer(theme),
      appBar: AppBar(
        title: const Text('Campus Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              _clearChatHistory();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load chat history: ${snapshot.error}',
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.hasData
                    ? snapshot.data!.docs
                          .map(
                            (document) => ChatMessage.fromFirestore(document),
                          )
                          .toList()
                    : _messages;
                if (snapshot.hasData) {
                  _messages
                    ..clear()
                    ..addAll(messages);
                }
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Ask Campus AI a question to get started.'),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _ChatBubble(message: messages[index]),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  if (_selectedImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _selectedImageBytes!,
                                height: 72,
                                width: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: InkWell(
                                onTap: _clearSelectedImage,
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Assistant is thinking...",
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Future<void> _clearChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await _messagesQuery(uid).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  Widget _buildProfileDrawer(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Student Profile'),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'S',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('User ID'),
            subtitle: Text(user?.uid ?? 'Not logged in'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromptChip('Where is the library?'),
                  _buildPromptChip('Show my timetable'),
                  _buildPromptChip('Exam rules'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: 'Attach image',
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(prompt),
        onPressed: () {
          _messageController.text = prompt;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: prompt.length),
          );
        },
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBytes,
    this.imageUrl,
  });

  static ChatMessage fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    final timestamp = data['timestamp'] as Timestamp?;
    return ChatMessage(
      text: data['text'] as String,
      isUser: data['isUser'] as bool,
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes != null || message.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: message.imageBytes == null
                      ? null
                      : () =>
                            _showFullScreenImage(context, message.imageBytes!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: message.imageBytes != null
                        ? Image.memory(message.imageBytes!, fit: BoxFit.cover)
                        : Image.network(message.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageBytes),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
