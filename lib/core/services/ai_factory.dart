import 'package:clarity_ai/core/services/ai_service.dart';
import 'package:clarity_ai/core/services/storage_service.dart';

class AiFactory {
  static Future<AiService?> create() async {
    final storage = StorageService();
    final provider = await storage.getAiProvider();

    if (provider == 'Local Device') {
      return LocalAiService();
    }

    if (provider == 'Ollama') {
      final ollamaConfig = await storage.getOllamaSettings();
      final endpoint = ollamaConfig['endpoint'] ?? 'http://10.0.2.2:11434';
      final model = ollamaConfig['model'] ?? 'llama3';
      return OllamaAiService(endpoint: endpoint, model: model);
    }
    
    if (provider == 'Custom') {
      final customConfig = await storage.getCustomProviderSettings();
      return CustomAiService(
        apiKey: customConfig['apiKey'] ?? '',
        baseUrl: customConfig['baseUrl'] ?? '',
        model: customConfig['model'] ?? '',
      );
    }

    // Default to API Key based providers (Gemini, ChatGPT, Groq)
    final apiKey = await storage.getApiKey(provider) ?? '';
    if (apiKey.isNotEmpty) {
      if (provider == 'OpenAI') return OpenAiService(apiKey: apiKey);
      if (provider == 'Gemini') return GeminiAiService(apiKey: apiKey);
      return GroqAiService(apiKey: apiKey);
    }
    
    return null;
  }
}
