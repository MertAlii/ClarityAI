import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/models/v2_models.dart' as v2;
import 'package:clarity_ai/core/models/note.dart' as old;

class ChatDetailPage extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatDetailPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final List<v2.ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  AiService? _aiService;
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final groqKey = prefs.getString('groq_api_key');
    if (groqKey != null && groqKey.isNotEmpty) {
      _aiService = GroqAiService(apiKey: groqKey);
    } // OpenAi or Gemini parsing could be added if needed based on settings

    final msgs = await DatabaseService.instance.getMessagesForSession(widget.sessionId);
    if (mounted) {
      setState(() {
        _messages.addAll(msgs);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _aiService == null) return;
    
    HapticFeedback.lightImpact();
    _textController.clear();
    
    final userMsg = v2.ChatMessage(
      id: const Uuid().v4(),
      sessionId: widget.sessionId,
      content: text,
      isUser: 1,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();
    
    await DatabaseService.instance.insertChatMessage(userMsg);

    try {
      final v2Notes = await DatabaseService.instance.getAllNotes();
      
      final oldNotes = v2Notes.map((n) => old.Note(
        id: n.id,
        title: n.title,
        referenceText: '', // Placeholder, V3 logic splits contents differently
        transcript: '',
        score: n.score ?? 0,
        targetAudience: n.targetAudience,
      )).toList();

      final responseText = await _aiService!.chat(
        message: text,
        userNotes: oldNotes,
      );

      final aiMsg = v2.ChatMessage(
        id: const Uuid().v4(),
        sessionId: widget.sessionId,
        content: responseText,
        isUser: 0,
        timestamp: DateTime.now(),
      );

      await DatabaseService.instance.insertChatMessage(aiMsg);
      
      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isTyping = false;
        });
        _scrollToBottom();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e', style: GoogleFonts.inter())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sohbet', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Color(0xFF84CC16), strokeWidth: 2),
                        ),
                      );
                    }
                    final msg = _messages[index];
                    final isUser = msg.isUser == 1;

                    // Parse AI message formatting for Notes linkage
                    String displayContent = msg.content;
                    if (!isUser) {
                      displayContent = displayContent.replaceAllMapped(
                        RegExp(r'@\[\[(.*?)\|(.*?)\]\]'),
                        (match) => '[${match.group(1)}](/note/${match.group(2)})'
                      );
                    }

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF84CC16).withOpacity(0.2) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUser ? const Color(0xFF84CC16).withOpacity(0.5) : const Color(0xFF2E2E2E)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: isUser 
                          ? Text(msg.content, style: GoogleFonts.inter(color: Colors.white))
                          : MarkdownBody(
                              data: displayContent,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.inter(color: Colors.white),
                                a: GoogleFonts.inter(color: const Color(0xFF84CC16), decoration: TextDecoration.underline),
                              ),
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  context.push(href);
                                }
                              },
                            ),
                      ),
                    );
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2E2E2E))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Bir şeyler yazın...',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFF242424),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF84CC16), shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
