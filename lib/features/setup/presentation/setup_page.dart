import 'package:flutter/material.dart';
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
  
  // AI Settings
  String _selectedProvider = '';
  String _apiKey = '';
  String _customBaseUrl = '';
  String _customModel = '';

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
    
    // Save API Key or Custom settings
    if (_selectedProvider == 'Custom') {
      await storage.saveCustomProviderSettings(
        baseUrl: _customBaseUrl.trim(),
        model: _customModel.trim(),
        apiKey: _apiKey.trim(),
      );
    } else if (_selectedProvider != 'Local Device') {
      await storage.saveApiKey(_selectedProvider, _apiKey.trim());
    }
    await storage.saveAiProvider(_selectedProvider);

    // Save User Profile
    await storage.saveUserProfile(UserProfile(
      name: _name,
      aiProvider: _selectedProvider,
      onboardingCompleted: true,
      setupCompleted: true,
      themeMode: _selectedTheme,
    ));

    // Apply Theme globally
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

  bool _isAiStepValid() {
    if (_selectedProvider.isEmpty) return false;
    if (_selectedProvider == 'Local Device') return true;
    if (_selectedProvider == 'Custom') {
      return _customBaseUrl.isNotEmpty && _customModel.isNotEmpty;
    }
    return _apiKey.isNotEmpty;
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

  Widget _buildThemeStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tema Tercihiniz', style: theme.textTheme.headlineLarge),
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
          Text('Adınız Nedir?', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Sizi nasıl karşılayalım?', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 48),
          TextField(
            onChanged: (val) => setState(() => _name = val),
            style: theme.textTheme.headlineSmall,
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
          Center(child: Text('Yapay Zeka Motorunu Seçin', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center)),
          const SizedBox(height: 32),
          Text('Bulut Çözümleri', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          _buildAiOption('Gemini', 'Google Gemini', LucideIcons.sparkles),
          const SizedBox(height: 12),
          _buildAiOption('OpenAI', 'ChatGPT (OpenAI)', LucideIcons.bot),
          const SizedBox(height: 12),
          _buildAiOption('Groq', 'Groq (Hızlı Model)', LucideIcons.zap),
          
          const SizedBox(height: 32),
          Text('Yerel & Özel Çözümler', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 16),
          _buildAiOption('Custom', 'Diğer (Kendi Sunucum / Ollama)', LucideIcons.server),
          const SizedBox(height: 12),
          _buildAiOption('Local Device', 'Model İndir (Yerel Cihaz)', LucideIcons.downloadCloud),
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAiStepValid() ? _nextStep : null,
              child: const Text('Kaydet ve Başla'),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildAiOption(String id, String label, IconData icon) {
    final isSelected = _selectedProvider == id;
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () => setState(() {
        _selectedProvider = id;
        _apiKey = '';
        _customBaseUrl = '';
        _customModel = '';
      }),
      borderColor: isSelected ? theme.primaryColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.bold : null)),
              const Spacer(),
              if (isSelected) Icon(LucideIcons.check, color: theme.primaryColor),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 16),
            if (id == 'Custom') ...[
              TextFormField(
                key: ValueKey('baseUrl_setup_$_selectedProvider'),
                initialValue: _customBaseUrl,
                onChanged: (val) => setState(() => _customBaseUrl = val),
                decoration: const InputDecoration(labelText: 'URL Endpoint', prefixIcon: Icon(LucideIcons.link)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('model_setup_$_selectedProvider'),
                initialValue: _customModel,
                onChanged: (val) => setState(() => _customModel = val),
                decoration: const InputDecoration(labelText: 'Model Adı', prefixIcon: Icon(LucideIcons.box)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('key_setup_$_selectedProvider'),
                initialValue: _apiKey,
                onChanged: (val) => setState(() => _apiKey = val),
                obscureText: true,
                decoration: const InputDecoration(labelText: 'API Anahtarı', prefixIcon: Icon(LucideIcons.key)),
              ),
            ] else if (id != 'Local Device') ...[
              TextFormField(
                key: ValueKey('key_setup_$_selectedProvider'),
                initialValue: _apiKey,
                onChanged: (val) => setState(() => _apiKey = val),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '$label API Anahtarı',
                  prefixIcon: const Icon(LucideIcons.key),
                ),
              ),
            ] else if (id == 'Local Device') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hiçbir veri sunucuya gitmez. Yaklaşık 2GB model dosyası indirilecek.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }
}
