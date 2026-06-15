import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/providers/data_providers.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/widgets/create_folder_dialog.dart';

class NoteCreationPage extends ConsumerStatefulWidget {
  const NoteCreationPage({super.key});

  @override
  ConsumerState<NoteCreationPage> createState() => _NoteCreationPageState();
}

class _NoteCreationPageState extends ConsumerState<NoteCreationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedAudience = 'university'; // Default
  Folder? _selectedFolder;
  bool _isLoading = false;

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        
        final File file = File(result.files.single.path!);
        final List<int> bytes = await file.readAsBytes();
        
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final String text = PdfTextExtractor(document).extractText();
        document.dispose();

        setState(() {
          _contentController.text = text;
          if (_titleController.text.isEmpty) {
            _titleController.text = result.files.single.name.replaceAll('.pdf', '');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF okuma hatası: $e')));
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir konu başlığı girin.')));
      return;
    }
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir referans metni girin veya PDF yükleyin.')));
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final note = Note(
      title: _titleController.text.trim(),
      targetAudience: _selectedAudience,
      folderId: _selectedFolder?.id,
      createdAt: DateTime.now(),
    );

    final noteId = await DatabaseService.instance.insertNote(note);
    
    final material = NoteMaterial(
      noteId: noteId,
      type: 'text', // It's just extracted text for now
      title: 'Ana Materyal',
      content: _contentController.text.trim(),
      createdAt: DateTime.now(),
    );
    await DatabaseService.instance.insertNoteMaterial(material);

    setState(() => _isLoading = false);

    if (mounted) {
      ref.invalidate(notesProvider);
      context.pushReplacement('/studio/$noteId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Not Oluştur')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Konu Adı', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Örn: Asenkron Programlama'),
                  ),
                  
                  const SizedBox(height: 24),
                  Text('Klasör (Opsiyonel)', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  foldersAsync.when(
                    data: (folders) {
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Folder>(
                              value: _selectedFolder,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              hint: const Text('Klasör Seçin'),
                              items: [
                                const DropdownMenuItem<Folder>(
                                  value: null,
                                  child: Text('Klasör Yok'),
                                ),
                                ...folders.map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.name),
                                ))
                              ],
                              onChanged: (val) {
                                setState(() => _selectedFolder = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.folderPlus),
                            onPressed: () {
                              showCreateFolderDialog(context, ref);
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Hata: $e'),
                  ),

                  const SizedBox(height: 32),
                  Text('Hedef Kitle', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildAudienceCard('child', 'Çocuk', LucideIcons.baby),
                      const SizedBox(width: 8),
                      _buildAudienceCard('university', 'Üniversiteli', LucideIcons.graduationCap),
                      const SizedBox(width: 8),
                      _buildAudienceCard('expert', 'Uzman', LucideIcons.briefcase),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text('Referans Materyali', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickPDF,
                      icon: const Icon(LucideIcons.fileUp),
                      label: const Text('PDF Yükle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('veya')),
                  ),

                  TextField(
                    controller: _contentController,
                    maxLines: 10,
                    minLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Metin Yapıştır...\n(Gerçek doğru veri olarak kabul edilecek)',
                    ),
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAndContinue,
                      child: const Text('Anlatmaya Başla'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAudienceCard(String id, String label, IconData icon) {
    final isSelected = _selectedAudience == id;
    final theme = Theme.of(context);
    
    return Expanded(
      child: GlassCard(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedAudience = id);
        },
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderColor: isSelected ? theme.primaryColor : null,
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
