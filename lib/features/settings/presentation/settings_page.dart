import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/main.dart';
import 'package:clarity_ai/app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final StorageService _storage = StorageService();
  
  // State
  String _selectedTheme = 'system';
  String _name = '';
  String _selectedProvider = 'Groq';
  String _apiKey = '';
  String _customBaseUrl = '';
  String _customModel = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final profile = await _storage.getUserProfile();
    final theme = await _storage.getThemeMode();
    final provider = profile?.aiProvider ?? 'Groq';
    
    String apiKey = '';
    String cBaseUrl = '';
    String cModel = '';

    if (provider == 'Custom' || provider == 'Ollama') {
      final customSettings = provider == 'Custom' 
          ? await _storage.getCustomProviderSettings()
          : await _storage.getOllamaSettings();
      cBaseUrl = customSettings['endpoint'] ?? customSettings['baseUrl'] ?? '';
      cModel = customSettings['model'] ?? '';
      apiKey = customSettings['apiKey'] ?? '';
    } else if (provider != 'Local Device') {
      apiKey = await _storage.getApiKey(provider) ?? '';
    }

    if (mounted) {
      setState(() {
        _name = profile?.name ?? '';
        _selectedTheme = theme;
        _selectedProvider = provider;
        _apiKey = apiKey;
        _customBaseUrl = cBaseUrl;
        _customModel = cModel;
      });
    }
  }

  Future<void> _saveAiSettings() async {
    if (_selectedProvider == 'Custom' || _selectedProvider == 'Ollama') {
      if (_selectedProvider == 'Ollama') {
         await _storage.saveOllamaSettings(endpoint: _customBaseUrl, model: _customModel);
      } else {
        await _storage.saveCustomProviderSettings(
          baseUrl: _customBaseUrl,
          model: _customModel,
          apiKey: _apiKey,
        );
      }
    } else if (_selectedProvider != 'Local Device') {
      await _storage.saveApiKey(_selectedProvider, _apiKey);
    }
    await _storage.saveAiProvider(_selectedProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yapay zeka ayarları kaydedildi'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _saveProfileSettings() async {
    final oldProfile = await _storage.getUserProfile();
    if (oldProfile != null) {
      await _storage.saveUserProfile(UserProfile(
        name: _name,
        aiProvider: _selectedProvider,
        onboardingCompleted: oldProfile.onboardingCompleted,
        setupCompleted: oldProfile.setupCompleted,
        themeMode: _selectedTheme,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil ayarları kaydedildi'), backgroundColor: AppColors.success),
      );
    }
  }

  void _changeThemeMode(String mode) async {
    setState(() => _selectedTheme = mode);
    await _storage.saveThemeMode(mode);
    final tm = switch (mode) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    ref.read(themeModeProvider.notifier).state = tm;
  }

  void _changeAccentColor(Color color) async {
    await _storage.saveAccentColor(color.value);
    ref.read(seedColorProvider.notifier).setColor(color);
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 24),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentColor = ref.watch(seedColorProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.outfit(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 120),
        children: [
          // PROFIL SECTION
          _buildSectionTitle('PROFİL', theme),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: Icon(LucideIcons.user, color: colorScheme.primary),
                  ),
                  title: TextFormField(
                    key: ValueKey('name_$_name'),
                    initialValue: _name,
                    onChanged: (val) => _name = val,
                    style: GoogleFonts.inter(color: colorScheme.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'İsminiz',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(LucideIcons.check, color: colorScheme.primary),
                    onPressed: _saveProfileSettings,
                    tooltip: 'Kaydet',
                  ),
                ),
              ],
            ),
          ),

          // GÖRÜNÜM SECTION
          _buildSectionTitle('GÖRÜNÜM', theme),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(LucideIcons.palette, color: colorScheme.onSurfaceVariant),
                  title: Text('Tema Seçimi', style: GoogleFonts.inter(color: colorScheme.onSurface)),
                  trailing: DropdownButton<String>(
                    value: _selectedTheme,
                    underline: const SizedBox(),
                    dropdownColor: colorScheme.surfaceContainer,
                    icon: Icon(LucideIcons.chevronDown, color: colorScheme.onSurfaceVariant),
                    items: [
                      DropdownMenuItem(value: 'system', child: Text('Sistem', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'light', child: Text('Açık', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'dark', child: Text('Koyu', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                    ],
                    onChanged: (val) {
                      if (val != null) _changeThemeMode(val);
                    },
                  ),
                ),
                Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Uygulama Rengi', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AppColors.accentOptions.map((color) {
                          final isSelected = color == currentColor;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _changeAccentColor(color);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? colorScheme.onSurface : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)
                                ] : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // YAPAY ZEKA SECTION
          _buildSectionTitle('YAPAY ZEKA', theme),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(LucideIcons.cpu, color: colorScheme.onSurfaceVariant),
                  title: Text('Motor Seçimi', style: GoogleFonts.inter(color: colorScheme.onSurface)),
                  trailing: DropdownButton<String>(
                    value: _selectedProvider,
                    underline: const SizedBox(),
                    dropdownColor: colorScheme.surfaceContainer,
                    icon: Icon(LucideIcons.chevronDown, color: colorScheme.onSurfaceVariant),
                    items: [
                      DropdownMenuItem(value: 'Gemini', child: Text('Google Gemini', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'Groq', child: Text('Groq', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'Local Device', child: Text('Local Device', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'Ollama', child: Text('Ollama', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                      DropdownMenuItem(value: 'Custom', child: Text('Diğer (Özel)', style: GoogleFonts.inter(color: colorScheme.onSurface))),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        String apiKey = '';
                        String cBaseUrl = '';
                        String cModel = '';

                        if (val == 'Custom' || val == 'Ollama') {
                          final customSettings = val == 'Custom' 
                              ? await _storage.getCustomProviderSettings() 
                              : await _storage.getOllamaSettings();
                          cBaseUrl = customSettings['endpoint'] ?? customSettings['baseUrl'] ?? '';
                          cModel = customSettings['model'] ?? '';
                          apiKey = customSettings['apiKey'] ?? '';
                        } else if (val != 'Local Device') {
                          apiKey = await _storage.getApiKey(val) ?? '';
                        }

                        setState(() {
                          _selectedProvider = val;
                          _apiKey = apiKey;
                          _customBaseUrl = cBaseUrl;
                          _customModel = cModel;
                        });
                      }
                    },
                  ),
                ),
                
                if (_selectedProvider == 'Custom' || _selectedProvider == 'Ollama') ...[
                  Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          key: ValueKey('baseUrl_$_selectedProvider'),
                          initialValue: _customBaseUrl,
                          onChanged: (val) => _customBaseUrl = val,
                          style: GoogleFonts.inter(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'URL Endpoint',
                            prefixIcon: Icon(LucideIcons.link, color: colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey('model_$_selectedProvider'),
                          initialValue: _customModel,
                          onChanged: (val) => _customModel = val,
                          style: GoogleFonts.inter(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Model Adı',
                            prefixIcon: Icon(LucideIcons.box, color: colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        if (_selectedProvider == 'Custom') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            key: ValueKey('apiKey_custom_$_selectedProvider'),
                            initialValue: _apiKey,
                            onChanged: (val) => _apiKey = val,
                            obscureText: true,
                            style: GoogleFonts.inter(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'API Anahtarı',
                              prefixIcon: Icon(LucideIcons.key, color: colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (_selectedProvider != 'Local Device') ...[
                  Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      key: ValueKey('apiKey_$_selectedProvider'),
                      initialValue: _apiKey,
                      onChanged: (val) => _apiKey = val,
                      obscureText: true,
                      style: GoogleFonts.inter(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: '$_selectedProvider API Anahtarı',
                        prefixIcon: Icon(LucideIcons.key, color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
                
                Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                InkWell(
                  onTap: _saveAiSettings,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text('Ayarları Kaydet', style: GoogleFonts.inter(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // ÇEVRİMDIŞI ÇALIŞMA SECTION
          _buildSectionTitle('ÇEVRİMDIŞI ÇALIŞMA', theme),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(LucideIcons.downloadCloud, color: colorScheme.primary, size: 20),
              ),
              title: Text('Yerel Modelleri Yönet', style: GoogleFonts.inter(color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
              subtitle: Text('Gemma modellerini indir', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              trailing: Icon(LucideIcons.chevronRight, color: colorScheme.onSurfaceVariant),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/local-models');
              },
            ),
          ),

          // HAKKINDA SECTION
          _buildSectionTitle('HAKKINDA', theme),
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Icon(LucideIcons.graduationCap, size: 36, color: colorScheme.primary)),
                      ),
                      const SizedBox(height: 16),
                      Text('Clarity AI', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text('v4.0.0 On-Device Edition', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Icon(LucideIcons.user, color: colorScheme.primary, size: 20),
                  ),
                  title: Text('Mert Ali Alkan', style: GoogleFonts.inter(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text('Junior Software Developer', style: GoogleFonts.inter(color: colorScheme.primary, fontSize: 12)),
                ),
                Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
                ListTile(
                  leading: Icon(LucideIcons.github, color: colorScheme.onSurfaceVariant),
                  title: Text('GitHub Kaynak Kodları', style: GoogleFonts.inter(color: colorScheme.onSurface)),
                  trailing: Icon(LucideIcons.externalLink, color: colorScheme.onSurfaceVariant, size: 16),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final url = Uri.parse('https://github.com/MertAlii/ClarityAI');
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          ),

          // DANGER ZONE
          const SizedBox(height: 32),
          GlassCard(
            margin: EdgeInsets.zero,
            backgroundColor: colorScheme.error.withValues(alpha: 0.1),
            borderColor: colorScheme.error.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(4),
            child: ListTile(
              leading: Icon(LucideIcons.trash2, color: colorScheme.error),
              title: Text('Tüm Verileri Temizle', style: GoogleFonts.inter(color: colorScheme.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                HapticFeedback.mediumImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: colorScheme.surface,
                    title: Text('Emin misiniz?', style: GoogleFonts.outfit(color: colorScheme.onSurface)),
                    content: Text('Tüm notlarınız, sınavlarınız ve ayarlarınız silinecek. Bu işlem geri alınamaz.', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text('İptal', style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
                        onPressed: () => Navigator.pop(c, true),
                        child: Text('Evet, Sil', style: GoogleFonts.inter()),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _storage.clearAll();
                  if (mounted) context.go('/setup');
                }
              },
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
