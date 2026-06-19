import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clarity_ai/core/services/ai_factory.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/models/v2_models.dart';


class ChatDetailPage extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatDetailPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final List<ChatMessage> _messages = [];
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

  Future<void> _initChat() async {
    _aiService = await AiFactory.create();
    if (mounted) setState(() {});
  }

  Future<void> _initData() async {
    await _initChat();

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
    if (text.isEmpty) return;

    if (_aiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ayarlardan bir yapay zeka sağlayıcısı (Model) seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    HapticFeedback.lightImpact();
    _textController.clear();
    
    final userMsg = ChatMessage(
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
      final contextBuilder = <String>[];
      for (final n in v2Notes) {
        final materials = await DatabaseService.instance.getMaterialsForNote(n.id!);
        if (materials.isNotEmpty) {
           final content = materials.first.content;
           final safeContent = content.length > 1500 ? '${content.substring(0, 1500)}... (Metin çok uzun olduğu için kırpıldı)' : content;
           contextBuilder.add("Not #${n.id}: ${n.title}\nİÇERİK: $safeContent");
        }
      }
      final contextText = contextBuilder.join("\n\n---\n\n");
      
      final responseText = await _aiService!.chat(
        message: text,
        contextText: contextText,
      );

      final aiMsg = ChatMessage(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Sohbet', style: GoogleFonts.outfit(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2),
                        ),
                      );
                    }
                    final msg = _messages[index];
                    final isUser = msg.isUser == 1;

                    // Parse AI message formatting for Notes linkage
                    String displayContent = msg.content;
                    if (!isUser) {
                      displayContent = displayContent.replaceAllMapped(
                        RegExp(r'\[\[(.*?)\|(.*?)\]\]'),
                        (match) => '[${match.group(1)}](/note_detail/${match.group(2)})'
                      );
                    }

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUser ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: isUser 
                          ? Text(msg.content, style: GoogleFonts.inter(color: colorScheme.onSurface))
                          : MarkdownBody(
                              data: displayContent,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.inter(color: colorScheme.onSurface),
                                a: GoogleFonts.inter(color: colorScheme.primary, decoration: TextDecoration.underline),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: GoogleFonts.inter(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Bir şeyler yazın...',
                hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withValues(alpha: 0.24)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
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
              decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
              child: Icon(Icons.send, color: colorScheme.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
