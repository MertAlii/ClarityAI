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
import 'package:clarity_ai/core/services/ai_factory.dart';
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _initAiService();
  }

  Future<void> _initAiService() async {
    _aiService = await AiFactory.create();
    if (mounted) setState(() {});
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

    String? selectedType = 'test';
    int questionCount = 5;
    String difficulty = 'Orta';
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Sınav Üret', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sınav Türü', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    items: const [
                      DropdownMenuItem(value: 'test', child: Text('Çoktan Seçmeli (Test)')),
                      DropdownMenuItem(value: 'classic', child: Text('Klasik Soru')),
                      DropdownMenuItem(value: 'flashcard', child: Text('Hafıza Kartı (Flashcard)')),
                    ],
                    onChanged: (v) => setStateSB(() => selectedType = v),
                  ),
                  const SizedBox(height: 16),
                  Text('Soru Sayısı: $questionCount', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Slider(
                    value: questionCount.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    activeColor: Theme.of(context).colorScheme.primary,
                    label: questionCount.toString(),
                    onChanged: (v) => setStateSB(() => questionCount = v.toInt()),
                  ),
                  const SizedBox(height: 16),
                  Text('Zorluk Seviyesi', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: difficulty,
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    items: const [
                      DropdownMenuItem(value: 'Kolay', child: Text('Kolay')),
                      DropdownMenuItem(value: 'Orta', child: Text('Orta')),
                      DropdownMenuItem(value: 'Zor', child: Text('Zor')),
                      DropdownMenuItem(value: 'Uzman', child: Text('Uzman')),
                    ],
                    onChanged: (v) => setStateSB(() => difficulty = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    confirmed = true;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Üret'),
                ),
              ],
            );
          }
        );
      }
    );

    if (!confirmed || selectedType == null) return;

    setState(() => _isGeneratingQuiz = true);
    try {
      final materials = await DatabaseService.instance.getMaterialsForNote(widget.noteId);
      if (materials.isEmpty) {
        throw Exception('Not materyali bulunamadı.');
      }
      final refText = materials.map((m) => m.content).join('\n\n');

      final result = await _aiService!.generateQuiz(
        referenceText: refText, 
        type: selectedType!,
        count: questionCount,
        difficulty: difficulty,
      );
      
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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          title: Text(mat.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          content: SingleChildScrollView(
                            child: Text(mat.content, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Kapat', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                          ],
                        ),
                      );
                    },
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return const Center(child: Text('Henüz analiz yok. Anlatıma başlayın.'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final reportData = reports[index];
                  AiReport? reportObj;
                  try {
                    reportObj = AiReport.fromJson(jsonDecode(reportData.contentJson));
                  } catch (_) {}

                  if (reportObj == null) return const SizedBox();

                  String labelText;
                  Color labelColor;
                  if (reportObj.score < 40) {
                    labelText = "Daha fazla çalışman gerekiyor";
                    labelColor = Colors.red;
                  } else if (reportObj.score < 70) {
                    labelText = "İyi gidiyorsun, biraz daha geliştir";
                    labelColor = Colors.orange;
                  } else {
                    labelText = "Harika! Konuya hakimsin";
                    labelColor = Colors.green;
                  }

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.zero,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(value: reportObj.score / 100, color: labelColor, backgroundColor: labelColor.withValues(alpha: 0.2)),
                            Text("${reportObj.score.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 12)),
                          ],
                        ),
                        title: Text('Analiz Raporu', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        subtitle: Text('${reportData.createdAt.toLocal().toString().substring(0,16)} • $labelText', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16).copyWith(top: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (reportObj.gaps.isNotEmpty) ...[
                                  Text('Eksikler ve Hatalar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ...reportObj.gaps.map((g) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• ${g['title']}: ${g['detail']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  )),
                                  const SizedBox(height: 16),
                                ],
                                if (reportObj.jargon.isNotEmpty) ...[
                                  Text('Jargon Filtresi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const SizedBox(height: 8),
                                  ...reportObj.jargon.map((j) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• ${j['word']} -> Öneri: ${j['suggestion']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  )),
                                  const SizedBox(height: 16),
                                ],
                                if (reportObj.analogies.isNotEmpty) ...[
                                  Text('Önerilen Analojiler', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 8),
                                  ...reportObj.analogies.map((a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• ${a['topic']}: ${a['analogy']}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
                        context.push('/classic_quiz', extra: quiz);
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
