import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _groqKeyController = TextEditingController();
  final TextEditingController _openAiKeyController = TextEditingController();
  final TextEditingController _geminiKeyController = TextEditingController();
  
  double _llamaProgress = 0.0;
  double _gemmaProgress = 0.0;
  bool _isLlamaDownloading = false;
  bool _isGemmaDownloading = false;
  
  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _groqKeyController.text = prefs.getString('groq_api_key') ?? '';
        _openAiKeyController.text = prefs.getString('openai_api_key') ?? '';
        _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      });
    }
  }

  Future<void> _saveKey(String keyName, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyName, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Anahtarı kaydedildi', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF242424),
        ),
      );
    }
  }
  
  void _simulateDownload(String model) {
    if (model == 'llama') {
      setState(() => _isLlamaDownloading = true);
      _simulateProgress((p) => setState(() => _llamaProgress = p), () => setState(() => _isLlamaDownloading = false));
    } else {
      setState(() => _isGemmaDownloading = true);
      _simulateProgress((p) => setState(() => _gemmaProgress = p), () => setState(() => _isGemmaDownloading = false));
    }
  }
  
  void _simulateProgress(Function(double) onProgress, VoidCallback onDone) async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) onProgress(i / 10.0);
    }
    if (mounted) onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Ayarlar', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Uygulama Ayarları
          Text('Uygulama Ayarları', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined, color: Colors.white),
              title: Text('Tema', style: GoogleFonts.inter(color: Colors.white)),
              trailing: DropdownButton<String>(
                value: 'Koyu',
                dropdownColor: const Color(0xFF1A1A1A),
                style: GoogleFonts.inter(color: Colors.white),
                underline: const SizedBox(),
                items: ['Açık', 'Koyu', 'Sistem'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  // handle theme
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Yapay Zeka ve Kotalar
          Text('Yapay Zeka ve Kotalar', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => context.push('/stats'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.analytics_outlined, color: Colors.white),
              title: Text('İstatistikler (Meraklısına)', style: GoogleFonts.inter(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API Anahtarları', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                _buildApiField('Groq API Key', _groqKeyController, (v) => _saveKey('groq_api_key', v)),
                const SizedBox(height: 8),
                _buildApiField('OpenAI API Key', _openAiKeyController, (v) => _saveKey('openai_api_key', v)),
                const SizedBox(height: 8),
                _buildApiField('Gemini API Key', _geminiKeyController, (v) => _saveKey('gemini_api_key', v)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Yerel Modeller (GGUF)
          Text('Yerel Modeller (GGUF)', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              children: [
                _buildModelRow('Llama-3-8b.gguf', '4.7 GB', _isLlamaDownloading, _llamaProgress, () => _simulateDownload('llama')),
                const Divider(color: Colors.white10, height: 24),
                _buildModelRow('Gemma-2b.gguf', '1.4 GB', _isGemmaDownloading, _gemmaProgress, () => _simulateDownload('gemma')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Hakkında
          Text('Hakkında', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF84CC16), width: 2),
                  ),
                  child: const Center(child: Icon(Icons.school, size: 40, color: Color(0xFF84CC16))),
                ),
                const SizedBox(height: 12),
                Text('Clarity AI', style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                Text('v3.0.0 LMS Edition', style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
                const SizedBox(height: 24),
                
                // Developer Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF242424),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alkan', style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Junior Software Developer', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF59E0B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.white.withOpacity(0.02),
                  leading: const Icon(Icons.code, color: Colors.white),
                  title: Text('GitHub', style: GoogleFonts.inter(color: Colors.white)),
                  subtitle: const Text('MertAlii/ClarityAI', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final url = Uri.parse('https://github.com/MertAlii/ClarityAI');
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.white.withOpacity(0.02),
                  leading: const Icon(Icons.work_outline, color: Colors.white),
                  title: Text('LinkedIn', style: GoogleFonts.inter(color: Colors.white)),
                  subtitle: const Text('mer1alii', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final url = Uri.parse('https://linkedin.com/in/mer1alii');
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildApiField(String hint, TextEditingController controller, Function(String) onSubmitted) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF242424),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.save_outlined, color: Color(0xFF84CC16)),
          onPressed: () {
            HapticFeedback.lightImpact();
            onSubmitted(controller.text);
          },
        ),
      ),
      onSubmitted: (v) {
        HapticFeedback.lightImpact();
        onSubmitted(v);
      },
    );
  }

  Widget _buildModelRow(String name, String size, bool isDownloading, double progress, VoidCallback onDownload) {
    return Row(
      children: [
        const Icon(Icons.memory, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
              Text(size, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              if (isDownloading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFF84CC16),
                  borderRadius: BorderRadius.circular(4),
                ),
              ]
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!isDownloading && progress == 0.0)
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF84CC16)),
            onPressed: () {
              HapticFeedback.lightImpact();
              onDownload();
            },
          )
        else if (progress >= 1.0)
          const Icon(Icons.check_circle, color: Color(0xFF22C55E))
      ],
    );
  }
}
