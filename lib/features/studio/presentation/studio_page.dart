import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/models/note.dart';

class StudioPage extends StatefulWidget {
  final int noteId;
  const StudioPage({super.key, required this.noteId});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  
  Note? _note;
  bool _isLoading = true;
  bool _isAnalyzing = false;

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNote();
    _initSpeech();
  }

  Future<void> _loadNote() async {
    final note = await DatabaseService.instance.getNoteById(widget.noteId);
    setState(() {
      _note = note;
      _isLoading = false;
    });
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    await _speech.initialize(
      onError: (val) => print('onError: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _listen() async {
    HapticFeedback.mediumImpact();
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _liveTranscript = val.recognizedWords;
          }),
          localeId: 'tr_TR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _analyze() async {
    if (_note == null) return;
    
    final finalTranscript = _tabController.index == 0 ? _liveTranscript : _textController.text;
    if (finalTranscript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir şeyler anlatın.')));
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final storage = StorageService();
      final profile = await storage.getUserProfile();
      if (profile == null) throw Exception('Profil bulunamadı');

      final key = await storage.getApiKey(profile.aiProvider);
      if (key == null) throw Exception('API Anahtarı bulunamadı');

      AiService aiService;
      if (profile.aiProvider == 'groq') {
        aiService = GroqAiService(apiKey: key);
      } else if (profile.aiProvider == 'openai') {
        aiService = OpenAiService(apiKey: key);
      } else {
        aiService = GeminiAiService(apiKey: key);
      }

      final report = await aiService.analyzeExplanation(
        referenceText: _note!.referenceText,
        transcript: finalTranscript,
        targetAudience: _note!.targetAudience,
      );

      _note!.transcript = finalTranscript;
      _note!.score = report.score;
      await DatabaseService.instance.updateNote(_note!);

      // Since we simulate storing the JSON report in the db (or passing it via state in a real app, 
      // but here we just navigate and let ReportPage fetch the note. Wait, ReportPage needs the full report. 
      // In MVP we can encode the report into the transcript field or a new DB column. 
      // Since schema is fixed, let's just navigate. We actually only saved score to DB. 
      // For MVP, ReportPage will re-analyze OR we can pass the report. 
      // Let's pass the report via GoRouter extra.
      
      setState(() => _isAnalyzing = false);
      if (mounted) {
        context.pushReplacement('/report/${_note!.id}', extra: report);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_note == null) return const Scaffold(body: Center(child: Text('Not bulunamadı.')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_note!.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🎙️ Sesli Anlatım'),
            Tab(text: '⌨️ Yazılı Anlatım'),
          ],
        ),
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('Yapay Zeka Analiz Ediyor...', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Eksiklerinizi ve mantık hatalarınızı buluyoruz.', 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVoiceTab(),
                _buildTextTab(),
              ],
            ),
      bottomNavigationBar: _isAnalyzing ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _analyze,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Anlatımı Bitir ve Analiz Et'),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceTab() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  _liveTranscript.isEmpty ? "Konuşmak için aşağıdaki butona basın..." : _liveTranscript,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _liveTranscript.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _listen,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1.seconds).fadeOut(duration: 1.seconds),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? theme.colorScheme.error : theme.primaryColor,
                  ),
                  child: Icon(
                    _isListening ? LucideIcons.square : LucideIcons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: 'Konuyu kendi cümlelerinizle olabildiğince detaylı anlatın...',
        ),
      ),
    );
  }
}
