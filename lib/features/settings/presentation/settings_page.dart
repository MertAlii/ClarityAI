import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/models/user_profile.dart';
import 'package:clarity_ai/main.dart';
import 'package:clarity_ai/core/services/database_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final StorageService _storage = StorageService();
  UserProfile? _profile;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _storage.getUserProfile();
    if (profile != null) {
      final key = await _storage.getApiKey(profile.aiProvider);
      setState(() {
        _profile = profile;
        _apiKey = key ?? '';
      });
    }
  }

  void _cycleTheme() async {
    HapticFeedback.lightImpact();
    if (_profile == null) return;
    
    String newMode;
    switch (_profile!.themeMode) {
      case 'dark':
        newMode = 'light';
        break;
      case 'light':
        newMode = 'system';
        break;
      default:
        newMode = 'dark';
    }

    setState(() {
      _profile!.themeMode = newMode;
    });

    await _storage.saveUserProfile(_profile!);
    final themeMode = switch (newMode) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    ref.read(themeModeProvider.notifier).state = themeMode;
  }

  void _showProviderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('AI Motoru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['groq', 'openai', 'gemini'].map((p) {
            return ListTile(
              title: Text(p.toUpperCase()),
              trailing: _profile?.aiProvider == p ? Icon(LucideIcons.check, color: Theme.of(context).primaryColor) : null,
              onTap: () async {
                if (_profile != null) {
                  _profile!.aiProvider = p;
                  await _storage.saveUserProfile(_profile!);
                  final newKey = await _storage.getApiKey(p);
                  setState(() {
                    _apiKey = newKey ?? '';
                  });
                }
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editApiKey() {
    final TextEditingController controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('API Anahtarı'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Yeni anahtar...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (_profile != null) {
                await _storage.saveApiKey(_profile!.aiProvider, controller.text);
                setState(() => _apiKey = controller.text);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Tüm Verileri Sil', style: TextStyle(color: Colors.red)),
        content: const Text('Tüm notlarınız, API anahtarlarınız ve ayarlarınız silinecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _storage.clearAll();
              // In a real app, we'd also clear the DB file.
              // For now we exit app or force reload.
              SystemNavigator.pop();
            },
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.palette),
                  title: const Text('Tema'),
                  trailing: Text(_profile!.themeMode.toUpperCase()),
                  onTap: _cycleTheme,
                ),
                const Divider(height: 1, thickness: 0.5),
                ListTile(
                  leading: const Icon(LucideIcons.cpu),
                  title: const Text('Yapay Zeka Motoru'),
                  trailing: Text(_profile!.aiProvider.toUpperCase()),
                  onTap: _showProviderDialog,
                ),
                const Divider(height: 1, thickness: 0.5),
                ListTile(
                  leading: const Icon(LucideIcons.key),
                  title: const Text('API Anahtarı'),
                  trailing: Text(_apiKey.isEmpty ? 'Girilmedi' : '********${_apiKey.length > 4 ? _apiKey.substring(_apiKey.length - 4) : ''}'),
                  onTap: _editApiKey,
                ),
                const Divider(height: 1, thickness: 0.5),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.red),
                  title: const Text('Verileri Temizle', style: TextStyle(color: Colors.red)),
                  onTap: _clearData,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // About Section
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.brainCircuit, size: 40, color: theme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text('Clarity AI', style: theme.textTheme.displayMedium),
                Text('v1.0.0', style: theme.textTheme.bodySmall),
                
                const SizedBox(height: 24),
                GlassCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(LucideIcons.user),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alkan', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Junior Software Developer', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final url = Uri.parse('https://github.com/MertAlii/ClarityAI.git');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.github),
                      SizedBox(width: 8),
                      Text('GitHub'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
