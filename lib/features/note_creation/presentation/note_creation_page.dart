import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/models/note.dart';

class NoteCreationPage extends StatefulWidget {
  const NoteCreationPage({super.key});

  @override
  State<NoteCreationPage> createState() => _NoteCreationPageState();
}

class _NoteCreationPageState extends State<NoteCreationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedAudience = 'university'; // Default
  bool _isLoading = false;

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
      referenceText: _contentController.text.trim(),
      targetAudience: _selectedAudience,
      createdAt: DateTime.now(),
    );

    final noteId = await DatabaseService.instance.insertNote(note);
    setState(() => _isLoading = false);

    if (mounted) {
      context.pushReplacement('/studio/$noteId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  
                  const SizedBox(height: 32),
                  Text('Hedef Kitle', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildAudienceChip('child', 'Çocuk', LucideIcons.baby),
                      const SizedBox(width: 8),
                      _buildAudienceChip('university', 'Üniversiteli', LucideIcons.graduationCap),
                      const SizedBox(width: 8),
                      _buildAudienceChip('expert', 'Uzman', LucideIcons.briefcase),
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
                      label: const Text('Belge Yükle (PDF)'),
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
                      hintText: 'Metni buraya yapıştırın...\n(Gerçek doğru veri olarak kabul edilecek)',
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

  Widget _buildAudienceChip(String id, String label, IconData icon) {
    final isSelected = _selectedAudience == id;
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedAudience = id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : theme.colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
