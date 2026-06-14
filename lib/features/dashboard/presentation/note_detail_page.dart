import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final int noteId;
  const NoteDetailPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AiService? _aiService;
  bool _isGeneratingQuiz = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAiService();
  }

  Future<void> _initAiService() async {
    final storage = StorageService();
    final profile = await storage.getUserProfile();
    if (profile != null) {
      final key = await storage.getApiKey(profile.aiProvider);
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
    setState(() {});
  }

  Future<void> _addMaterial(String type) async {
    if (type == 'pdf') {
      try {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          final File file = File(result.files.single.path!);
          final List<int> bytes = await file.readAsBytes();
          
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          final String text = PdfTextExtractor(document).extractText();
          document.dispose();

          final material = NoteMaterial(
            noteId: widget.noteId,
            type: 'pdf',
            title: result.files.single.name,
            content: text,
            createdAt: DateTime.now(),
          );
          await DatabaseService.instance.insertNoteMaterial(material);
          ref.invalidate(noteMaterialsProvider(widget.noteId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF okuma hatası: $e')));
        }
      }
    } else {
      // Metin yapıştır dialog
      String title = '';
      String content = '';
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Metin Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Metin', hintText: 'Buraya yapıştırın...'),
                    maxLines: 5,
                    onChanged: (v) => content = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
              ElevatedButton(
                onPressed: () async {
                  if (title.isNotEmpty && content.isNotEmpty) {
                    final material = NoteMaterial(
                      noteId: widget.noteId,
                      type: 'text',
                      title: title,
                      content: content,
                      createdAt: DateTime.now(),
                    );
                    await DatabaseService.instance.insertNoteMaterial(material);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Ekle'),
              ),
            ],
          );
        }
      );
      ref.invalidate(noteMaterialsProvider(widget.noteId));
    }
  }

  Future<void> _generateQuiz() async {
    if (_aiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI servisi ayarlanmamış!')));
      return;
    }

    String? selectedType;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sınav Türü Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Çoktan Seçmeli (Test)'),
                onTap: () { selectedType = 'test'; Navigator.pop(ctx); },
              ),
              ListTile(
                title: const Text('Klasik Soru'),
                onTap: () { selectedType = 'classic'; Navigator.pop(ctx); },
              ),
              ListTile(
                title: const Text('Hafıza Kartı (Flashcard)'),
                onTap: () { selectedType = 'flashcard'; Navigator.pop(ctx); },
              ),
            ],
          ),
        );
      }
    );

    if (selectedType == null) return;

    setState(() => _isGeneratingQuiz = true);
    try {
      final materials = await DatabaseService.instance.getMaterialsForNote(widget.noteId);
      if (materials.isEmpty) {
        throw Exception('Not materyali bulunamadı.');
      }
      final refText = materials.map((m) => m.content).join('\n\n');

      final result = await _aiService!.generateQuiz(referenceText: refText, type: selectedType!);
      
      final quizData = QuizData(
        noteId: widget.noteId,
        type: selectedType!,
        contentJson: jsonEncode(result),
        createdAt: DateTime.now(),
      );
      await DatabaseService.instance.insertQuiz(quizData);
      ref.invalidate(quizzesProvider(widget.noteId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sınav başarıyla üretildi!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sınav üretim hatası: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuiz = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Detayları'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Materyaller', icon: Icon(LucideIcons.library)),
            Tab(text: 'Analiz & Özet', icon: Icon(LucideIcons.fileBarChart)),
            Tab(text: 'Sınavlar', icon: Icon(LucideIcons.brain)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMaterialsTab(),
          _buildReportsTab(),
          _buildQuizzesTab(),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    final materialsAsync = ref.watch(noteMaterialsProvider(widget.noteId));
    
    return Column(
      children: [
        Expanded(
          child: materialsAsync.when(
            data: (materials) {
              if (materials.isEmpty) return const Center(child: Text('Henüz materyal yok.'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: materials.length,
                itemBuilder: (context, index) {
                  final mat = materials[index];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(mat.type == 'pdf' ? LucideIcons.fileText : LucideIcons.alignLeft),
                      title: Text(mat.title),
                      subtitle: Text('${mat.content.length} karakter'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Hata: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addMaterial('pdf'),
                  icon: const Icon(LucideIcons.fileUp),
                  label: const Text('PDF Ekle'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addMaterial('text'),
                  icon: const Icon(LucideIcons.type),
                  label: const Text('Metin Ekle'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    final reportsAsync = ref.watch(aiReportsProvider(widget.noteId));

    return Column(
      children: [
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) return const Center(child: Text('Henüz analiz yok.'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(LucideIcons.barChart2),
                      title: Text('Analiz - ${report.createdAt.toLocal().toString().split('.')[0]}'),
                      subtitle: Text('Skor: ${report.score?.toStringAsFixed(1) ?? "N/A"}'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Hata: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/studio/${widget.noteId}'),
              icon: const Icon(LucideIcons.mic),
              label: const Text('Yeni Analiz İste (Studio)'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizzesTab() {
    final quizzesAsync = ref.watch(quizzesProvider(widget.noteId));

    return Column(
      children: [
        if (_isGeneratingQuiz) const LinearProgressIndicator(),
        Expanded(
          child: quizzesAsync.when(
            data: (quizzes) {
              if (quizzes.isEmpty) return const Center(child: Text('Henüz sınav yok.'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () {
                      if (quiz.type == 'flashcard') {
                        context.push('/flashcard_quiz', extra: quiz);
                      } else if (quiz.type == 'test') {
                        context.push('/test_quiz', extra: quiz);
                      } else {
                        // classic not fully implemented UI-wise, but route could be same or custom
                      }
                    },
                    child: ListTile(
                      leading: Icon(
                        quiz.type == 'flashcard' ? LucideIcons.layers : 
                        quiz.type == 'test' ? LucideIcons.listChecks : LucideIcons.penTool
                      ),
                      title: Text(
                        quiz.type == 'flashcard' ? 'Hafıza Kartları' :
                        quiz.type == 'test' ? 'Test Sınavı' : 'Klasik Sınav'
                      ),
                      subtitle: Text(quiz.createdAt.toLocal().toString().split('.')[0]),
                      trailing: quiz.score != null ? Text('Skor: ${quiz.score!.toStringAsFixed(0)}%') : null,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Hata: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingQuiz ? null : _generateQuiz,
              icon: const Icon(LucideIcons.plusCircle),
              label: const Text('Yeni Sınav Üret'),
            ),
          ),
        ),
      ],
    );
  }
}
