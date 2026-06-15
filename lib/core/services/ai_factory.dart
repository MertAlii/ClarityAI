import 'package:shared_preferences/shared_preferences.dart';
import 'package:clarity_ai/core/services/ai_service.dart';

class AiFactory {
  static Future<AiService?> create() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('ai_provider') ?? 'Groq';
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final endpoint = prefs.getString('ollama_endpoint') ?? 'http://10.0.2.2:11434';
    final model = prefs.getString('ollama_model') ?? 'llama3';

    if (provider == 'Ollama') {
      return OllamaAiService(endpoint: endpoint, model: model);
    } else if (apiKey.isNotEmpty) {
      if (provider == 'OpenAI') return OpenAiService(apiKey: apiKey);
      if (provider == 'Gemini') return GeminiAiService(apiKey: apiKey);
      return GroqAiService(apiKey: apiKey);
    }
    
    return null;
  }
}
