import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/models/note.dart';
import 'package:clarity_ai/models/user_profile.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;
  final StorageService _storage = StorageService();
  String _userName = '';
  AiService? _aiService;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storage.getUserProfile();
    if (profile != null) {
      setState(() => _userName = profile.name);
      final key = await _storage.getApiKey(profile.aiProvider);
      if (key != null) {
        if (profile.aiProvider == 'groq') {
          _aiService = GroqAiService(apiKey: key);
        } else if (profile.aiProvider == 'openai') {
          _aiService = OpenAiService(apiKey: key);
        } else if (profile.aiProvider == 'gemini') {
          _aiService = GeminiAiService(apiKey: key);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Kütüphane' : 'AI Asistan'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _currentIndex == 0 ? const _HomeTab() : _ChatTab(aiService: _aiService),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/create').then((_) => setState(() {}));
              },
              child: const Icon(LucideIcons.plus),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Ana Sayfa'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Chat'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: DatabaseService.instance.getAllNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final notes = snapshot.data ?? [];
        
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.folderOpen, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text('Henüz bir notunuz yok.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('İlk notunuzu oluşturmak için + butonuna tıklayın.', 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: notes.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('Merhaba, \nbugün ne öğreniyoruz?', style: Theme.of(context).textTheme.displayLarge),
              );
            }
            
            final note = notes[index - 1];
            final score = note.score ?? 0;
            Color scoreColor = Theme.of(context).colorScheme.error; // < 40
            if (score >= 40 && score < 70) scoreColor = Colors.orange;
            if (score >= 70) scoreColor = Colors.green;

            return GlassCard(
              margin: const EdgeInsets.only(bottom: 16),
              onTap: () => context.push('/report/${note.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(note.createdAt), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(note.title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 16),
                  if (note.score != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              color: scoreColor,
                              backgroundColor: scoreColor.withOpacity(0.2),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('%${score.toInt()}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scoreColor)),
                      ],
                    ),
                  ] else ...[
                    Text('Henüz analiz edilmedi', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChatTab extends StatefulWidget {
  final AiService? aiService;
  const _ChatTab({this.aiService});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await DatabaseService.instance.getChatMessages();
    if (msgs.isEmpty) {
      final initialMsg = ChatMessage(
        id: const Uuid().v4(),
        content: 'Merhaba! Ben öğrenme asistanınız. Notlarınız hakkında her şeyi sorabilirsiniz. 📚',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await DatabaseService.instance.insertChatMessage(initialMsg);
      msgs.add(initialMsg);
    }
    setState(() => _messages = msgs);
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.aiService == null) return;

    _textController.clear();
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    await DatabaseService.instance.insertChatMessage(userMsg);
    _scrollToBottom();

    try {
      final notes = await DatabaseService.instance.getAllNotes();
      final aiResponse = await widget.aiService!.chat(
        message: text,
        userNotes: notes,
        history: _messages,
      );

      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMsg);
        _isLoading = false;
      });
      await DatabaseService.instance.insertChatMessage(aiMsg);
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  List<InlineSpan> _parseMessageWithReferences(String content) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\[\[(.*?)\|(\d+)\]\]');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: content.substring(lastMatchEnd, match.start)));
      }

      final title = match.group(1)!;
      final noteIdStr = match.group(2)!;
      final noteId = int.tryParse(noteIdStr);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              if (noteId != null) {
                context.push('/report/$noteId');
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.fileText, size: 12, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.aiService == null) {
      return Center(child: Text('AI Motoru ayarlanmamış. Lütfen ayarlardan yapılandırın.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg.isUser;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isUser ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(0) : null,
                      bottomLeft: !isUser ? const Radius.circular(0) : null,
                    ),
                  ),
                  child: isUser 
                      ? Text(msg.content, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
                      : RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                            children: _parseMessageWithReferences(msg.content),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Bir şeyler sorun...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
