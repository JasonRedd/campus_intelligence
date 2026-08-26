import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Your API Key
  static const String _apiKey =
      'AQ.Ab8RN6LU0S-qdU2JwJ_ILTTxcI5RjaU5sLsedxX7akRY75kt_w';

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your Campus Assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final responseText = await _callGeminiApi(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Connection Error: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<String> _callGeminiApi(String prompt) async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    };

    final Map<String, dynamic> body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String? reply =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return reply ?? 'No text generated.';
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      final String errorMessage =
          errorData['error']?['message'] ?? 'HTTP ${response.statusCode}';
      return 'API Error: $errorMessage';
    }
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
      appBar: AppBar(
        title: const Text('Campus Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
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
        child: Row(
          children: [
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
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
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
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}