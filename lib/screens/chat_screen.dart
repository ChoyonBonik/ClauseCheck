import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';

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

class ChatScreen extends StatefulWidget {
  final ScanResult scanResult;

  const ChatScreen({super.key, required this.scanResult});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    'Can I terminate or cancel this early?',
    'Are there hidden penalty fees or deposits?',
    'What notice period do I have to provide?',
    'What is the single most dangerous clause here?',
    'Can I have pets or guests according to this?',
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message from AI
    _messages.add(
      ChatMessage(
        text:
            'Hello! I have reviewed your ${widget.scanResult.documentType} (Risk Score: ${widget.scanResult.riskScore}/100).\n\nAsk me anything about specific clauses, your rights, cancellation rules, or hidden costs.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Build history for backend
      final history = _messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'text': m.text,
              })
          .toList();

      final reply = await ApiService.askContractQuestion(
        documentContext: widget.scanResult.toContextString(),
        chatHistory: history,
        message: query,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: '⚠️ Could not get an answer: ${e.toString().replaceAll('Exception: ', '')}',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161F30),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask Contract AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              widget.scanResult.documentType,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Suggested chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final prompt = _suggestedPrompts[i];
                  return ActionChip(
                    backgroundColor: const Color(0xFF161F30),
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    onPressed: _isLoading ? null : () => _sendMessage(prompt),
                  );
                },
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Gemini is checking the contract clauses...',
                      style: TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Text input area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF161F30),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question about this document...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: _isLoading ? Colors.white24 : Colors.indigoAccent,
                    ),
                    onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.indigoAccent : const Color(0xFF161F30),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(color: msg.isUser ? Colors.transparent : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (!msg.isUser) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied response to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.copy_rounded, size: 13, color: Colors.white38),
                      SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontSize: 10, color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
