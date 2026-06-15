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
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  
  String _selectedProvider = 'Groq';
  String _selectedTheme = 'Koyu';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final savedProvider = (prefs.getString('ai_provider') ?? 'Groq').toLowerCase();
        if (savedProvider == 'openai') _selectedProvider = 'OpenAI';
        else if (savedProvider == 'gemini') _selectedProvider = 'Gemini';
        else if (savedProvider == 'ollama') _selectedProvider = 'Ollama';
        else _selectedProvider = 'Groq';

        _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
        _endpointController.text = prefs.getString('ollama_endpoint') ?? 'http://10.0.2.2:11434';
        _modelController.text = prefs.getString('ollama_model') ?? 'llama3';
        // Mock theme loading
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', _selectedProvider);
    await prefs.setString('ai_api_key', _apiKeyController.text.trim());
    await prefs.setString('ollama_endpoint', _endpointController.text.trim());
    await prefs.setString('ollama_model', _modelController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar kaydedildi', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF242424),
        ),
      );
    }
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
                value: _selectedTheme,
                dropdownColor: const Color(0xFF1A1A1A),
                style: GoogleFonts.inter(color: Colors.white),
                underline: const SizedBox(),
                items: ['Açık', 'Koyu', 'Sistem'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTheme = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Yapay Zeka Model Ayarları
          Text('Model ve Sağlayıcı Ayarları', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.memory, color: Colors.white),
                  title: Text('Yapay Zeka Sağlayıcısı', style: GoogleFonts.inter(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: _selectedProvider,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: GoogleFonts.inter(color: Colors.white),
                    underline: const SizedBox(),
                    items: ['Groq', 'OpenAI', 'Gemini', 'Ollama'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedProvider = val);
                    },
                  ),
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                
                if (_selectedProvider != 'Ollama') ...[
                  Text('$_selectedProvider API Anahtarı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildInputField('sk-...', _apiKeyController, isObscure: true),
                ] else ...[
                  Text('Ollama Özel Endpoint (URL)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Örn: http://10.0.2.2:11434 veya kendi domaininiz', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildInputField('http://...', _endpointController),
                  const SizedBox(height: 16),
                  Text('Model Adı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Örn: llama3, gemma2', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildInputField('llama3', _modelController),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _saveSettings();
                    },
                    child: Text('Ayarları Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text('İstatistikler', style: GoogleFonts.outfit(color: const Color(0xFF84CC16), fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => context.push('/stats'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.analytics_outlined, color: Colors.white),
              title: Text('Token & API Kullanımları (Meraklısına)', style: GoogleFonts.inter(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
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
                            Text('Mert Ali Alkan', style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Software Developer', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFF59E0B))),
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

  Widget _buildInputField(String hint, TextEditingController controller, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF242424),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
