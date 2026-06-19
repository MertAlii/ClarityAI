import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';

class LocalModelPage extends ConsumerStatefulWidget {
  const LocalModelPage({super.key});

  @override
  ConsumerState<LocalModelPage> createState() => _LocalModelPageState();
}

class _LocalModelPageState extends ConsumerState<LocalModelPage> {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isModelInstalled = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() {
      _isModelInstalled = false; // Mock initialization
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      // Simulate download progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _progress = i / 100.0);
      }

      setState(() {
        _isDownloading = false;
        _isModelInstalled = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemma modeli başarıyla indirildi ve kuruldu!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İndirme hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _deleteModel() {
    setState(() {
      _isModelInstalled = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Model cihazdan kaldırıldı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Yerel Modeller', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.cpu, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Google Gemma 2B (IT)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          Text('Cihaz İçi Hafif Sürüm • ~1.5 GB', style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Bu model doğrudan cihazınızın işlemcisini kullanır. İnternet bağlantısı gerektirmez ve verileriniz cihazdan dışarı çıkmaz.', style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                const SizedBox(height: 24),
                
                if (_isDownloading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('İndiriliyor...', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          Text('${(_progress * 100).toInt()}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                        minHeight: 8,
                      ),
                    ],
                  )
                else if (_isModelInstalled)
                  Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.green.shade400),
                      const SizedBox(width: 8),
                      Text('Kurulu ve Hazır', style: GoogleFonts.inter(color: Colors.green.shade400, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _deleteModel,
                        icon: Icon(LucideIcons.trash2, color: colorScheme.error, size: 18),
                        label: Text('Sil', style: TextStyle(color: colorScheme.error)),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _downloadModel,
                      icon: const Icon(LucideIcons.download),
                      label: const Text('İndir ve Kur'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
