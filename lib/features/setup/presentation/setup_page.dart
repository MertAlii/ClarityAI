import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clarity_ai/core/widgets/glass_card.dart';
import 'package:clarity_ai/core/services/storage_service.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/main.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  String _selectedTheme = 'system';
  String _name = '';
  String _selectedProvider = '';
  String _apiKey = '';
  String _ollamaEndpoint = 'http://10.0.2.2:11434';
  String _ollamaModel = 'llama3';

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    final storage = StorageService();
    final prefs = await SharedPreferences.getInstance();
    
    // Save User Profile
    await storage.saveUserProfile(UserProfile(
      name: _name,
      aiProvider: _selectedProvider,
      onboardingCompleted: true,
      setupCompleted: true,
      themeMode: _selectedTheme,
    ));

    // Save API Key & Ollama settings
    if (_selectedProvider == 'Ollama') {
      await prefs.setString('ollama_endpoint', _ollamaEndpoint.trim());
      await prefs.setString('ollama_model', _ollamaModel.trim());
    } else {
      await storage.saveApiKey(_selectedProvider, _apiKey.trim());
    }
    await prefs.setString('ai_provider', _selectedProvider);

    // Apply Theme
    final themeMode = switch (_selectedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    ref.read(themeModeProvider.notifier).state = themeMode;

    if (mounted) {
      context.go('/');
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildThemeStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tema Tercihiniz', style: theme.textTheme.displayMedium),
          const SizedBox(height: 32),
          _buildThemeOption('dark', 'Koyu Tema', LucideIcons.moon),
          const SizedBox(height: 16),
          _buildThemeOption('light', 'Açık Tema', LucideIcons.sun),
          const SizedBox(height: 16),
          _buildThemeOption('system', 'Sistem Ayarları', LucideIcons.smartphone),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Devam'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String value, String label, IconData icon) {
    final isSelected = _selectedTheme == value;
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () {
        setState(() => _selectedTheme = value);
        // Preview theme
        final previewMode = switch (value) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          _ => ThemeMode.system,
        };
        ref.read(themeModeProvider.notifier).state = previewMode;
      },
      borderColor: isSelected ? theme.primaryColor : null,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface),
          const SizedBox(width: 16),
          Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : null)),
          const Spacer(),
          if (isSelected) Icon(LucideIcons.check, color: theme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Adınız Nedir?', style: theme.textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Sizi nasıl karşılayalım?', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 48),
          TextField(
            onChanged: (val) => setState(() => _name = val),
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Örn: Mert',
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _name.trim().isNotEmpty ? _nextStep : null,
              child: const Text('Devam'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Center(child: Text('Yapay Zeka Motorunu Seçin', style: theme.textTheme.displayMedium, textAlign: TextAlign.center)),
          const SizedBox(height: 32),
          Text('Bulut Çözümleri', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          _buildAiOption('Groq', '🚀 Groq (Llama 3 - Hızlı)'),
          const SizedBox(height: 12),
          _buildAiOption('OpenAI', '🧠 OpenAI (GPT-4o)'),
          const SizedBox(height: 12),
          _buildAiOption('Gemini', '✨ Google Gemini'),
          
          const SizedBox(height: 32),
          Text('Yerel Çözümler', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          _buildAiOption('Ollama', '💻 Kendi Sunucum (Ollama)'),
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedProvider.isNotEmpty && (_selectedProvider == 'Ollama' ? (_ollamaEndpoint.isNotEmpty && _ollamaModel.isNotEmpty) : _apiKey.isNotEmpty)) ? _nextStep : null,
              child: const Text('Kaydet ve Başla'),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildAiOption(String id, String label) {
    final isSelected = _selectedProvider == id;
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () => setState(() {
        _selectedProvider = id;
        _apiKey = ''; // Reset key on provider change
      }),
      borderColor: isSelected ? theme.primaryColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : null)),
              const Spacer(),
              if (isSelected) Icon(LucideIcons.check, color: theme.primaryColor),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 16),
            if (id == 'Ollama') ...[
              TextField(
                onChanged: (val) => setState(() => _ollamaEndpoint = val),
                decoration: InputDecoration(
                  hintText: 'Endpoint (Örn: http://10.0.2.2:11434)',
                  prefixIcon: const Icon(LucideIcons.link),
                ),
                controller: TextEditingController(text: _ollamaEndpoint),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => setState(() => _ollamaModel = val),
                decoration: InputDecoration(
                  hintText: 'Model Adı (Örn: llama3)',
                  prefixIcon: const Icon(LucideIcons.box),
                ),
                controller: TextEditingController(text: _ollamaModel),
              ),
            ] else ...[
              TextField(
                onChanged: (val) => setState(() => _apiKey = val),
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '$id API Anahtarını Girin',
                  prefixIcon: const Icon(LucideIcons.key),
                ),
              ),
            ]
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildThemeStep(),
                  _buildNameStep(),
                  _buildAiStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
