class AiConfig {
  String providerName; // 'groq', 'openai', 'gemini'
  String apiKey;
  String? modelName;
  String? customEndpoint;

  AiConfig({
    required this.providerName,
    required this.apiKey,
    this.modelName,
    this.customEndpoint,
  });
}
