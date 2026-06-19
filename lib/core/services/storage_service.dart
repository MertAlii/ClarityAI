import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clarity_ai/models/v2_models.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  // --- API KEYS (Secure Storage) ---
  Future<void> saveApiKey(String provider, String key) async {
    await _secureStorage.write(key: '${provider}_api_key', value: key);
    // Also mirror to SharedPreferences for AiFactory compatibility
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', key);
  }

  Future<String?> getApiKey(String provider) async {
    return await _secureStorage.read(key: '${provider}_api_key');
  }

  Future<void> deleteApiKey(String provider) async {
    await _secureStorage.delete(key: '${provider}_api_key');
  }

  // --- AI PROVIDER SETTINGS ---
  Future<void> saveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', provider);
  }

  Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ai_provider') ?? 'Gemini';
  }

  Future<void> saveOllamaSettings({required String endpoint, required String model}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_endpoint', endpoint);
    await prefs.setString('ollama_model', model);
  }

  Future<Map<String, String>> getOllamaSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'endpoint': prefs.getString('ollama_endpoint') ?? 'http://10.0.2.2:11434',
      'model': prefs.getString('ollama_model') ?? 'llama3',
    };
  }

  Future<void> saveCustomProviderSettings({
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', baseUrl);
    await prefs.setString('custom_model', model);
    await _secureStorage.write(key: 'custom_api_key', value: apiKey);
  }

  Future<Map<String, String>> getCustomProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = await _secureStorage.read(key: 'custom_api_key') ?? '';
    return {
      'baseUrl': prefs.getString('custom_base_url') ?? '',
      'model': prefs.getString('custom_model') ?? '',
      'apiKey': apiKey,
    };
  }

  // --- ACCENT COLOR ---
  Future<void> saveAccentColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', colorValue);
  }

  Future<int?> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('accent_color');
  }

  // --- QUOTA SETTINGS ---
  Future<void> saveDailyQuota(int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_token_quota', tokens);
  }

  Future<int> getDailyQuota() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('daily_token_quota') ?? 100000;
  }

  Future<void> saveWeeklyQuota(int tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weekly_token_quota', tokens);
  }

  Future<int> getWeeklyQuota() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weekly_token_quota') ?? 500000;
  }

  // --- USER PROFILE ---
  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', profile.name);
    await prefs.setString('ai_provider', profile.aiProvider);
    await prefs.setBool('onboarding_completed', profile.onboardingCompleted);
    await prefs.setBool('setup_completed', profile.setupCompleted);
    await prefs.setString('theme_mode', profile.themeMode);
  }

  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final aiProvider = prefs.getString('ai_provider');
    
    if (name == null || aiProvider == null) {
      return null;
    }

    return UserProfile(
      name: name,
      aiProvider: aiProvider,
      onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
      setupCompleted: prefs.getBool('setup_completed') ?? false,
      themeMode: prefs.getString('theme_mode') ?? 'system',
    );
  }

  // --- INDIVIDUAL PREFS ---
  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', value);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> setSetupCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', value);
  }

  Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setup_completed') ?? false;
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') ?? 'system';
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Kullanıcı';
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
