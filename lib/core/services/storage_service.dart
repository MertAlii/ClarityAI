import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clarity_ai/models/v2_models.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  // --- API KEYS ---
  Future<void> saveApiKey(String provider, String key) async {
    await _secureStorage.write(key: '${provider}_api_key', value: key);
  }

  Future<String?> getApiKey(String provider) async {
    return await _secureStorage.read(key: '${provider}_api_key');
  }

  Future<void> deleteApiKey(String provider) async {
    await _secureStorage.delete(key: '${provider}_api_key');
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

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
