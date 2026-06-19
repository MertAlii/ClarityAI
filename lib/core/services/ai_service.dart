import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:clarity_ai/models/v2_models.dart';
import 'package:clarity_ai/core/constants/prompts.dart';
import 'package:clarity_ai/core/services/database_service.dart';

String _cleanJson(String raw) {
  int startObj = raw.indexOf('{');
  int startArr = raw.indexOf('[');
  int startIndex = -1;
  if (startObj != -1 && startArr != -1) {
    startIndex = startObj < startArr ? startObj : startArr;
  } else {
    startIndex = startObj != -1 ? startObj : startArr;
  }

  int endObj = raw.lastIndexOf('}');
  int endArr = raw.lastIndexOf(']');
  int endIndex = endObj > endArr ? endObj : endArr;

  if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }
  
  return raw.substring(startIndex, endIndex + 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Abstract contract
// ─────────────────────────────────────────────────────────────────────────────

abstract class AiService {
  Future<AiReport> analyzeExplanation({
    required String referenceText,
    required String transcript,
    required String targetAudience,
  });

  Future<String> chat({
    required String message,
    required String contextText,
    List<ChatMessage>? history,
  });

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
    int count = 5,
    String difficulty = 'Orta',
  });

  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({
    required String referenceText,
    required String type,
    required String mistakes,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Base implementation for all OpenAI-compatible APIs (Groq, OpenAI, Ollama…)
// ─────────────────────────────────────────────────────────────────────────────

class BaseOpenAiCompatibleService implements AiService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final String providerLabel;
  final Dio _dio;

  BaseOpenAiCompatibleService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.providerLabel,
  }) : _dio = Dio() {
    if (apiKey.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    }
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 120);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<void> _trackUsage(String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage(providerLabel, tokens);
  }

  Future<String> _post({
    required List<Map<String, String>> messages,
    double temperature = 0.1,
  }) async {
    final response = await _dio.post(
      '$baseUrl/chat/completions',
      data: {
        'model': model,
        'messages': messages,
        'temperature': temperature,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  // ── AiService implementation ─────────────────────────────────────────────

  @override
  Future<AiReport> analyzeExplanation({
    required String referenceText,
    required String transcript,
    required String targetAudience,
  }) async {
    final audienceLabel =
        Prompts.audienceLabels[targetAudience] ?? targetAudience;
    final prompt = Prompts.feynmanAnalysisPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{transcript}', transcript)
        .replaceAll('{audience}', audienceLabel);

    try {
      final content = await _post(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );
      await _trackUsage(prompt, content);
      return AiReport.fromJson(jsonDecode(_cleanJson(content)));
    } catch (e) {
      throw Exception('$providerLabel API Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required String contextText,
    List<ChatMessage>? history,
  }) async {
    final systemPrompt =
        Prompts.chatPrompt.replaceAll('{notesContext}', contextText);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    if (history != null) {
      for (final msg in history) {
        messages.add({
          'role': msg.isUser == 1 ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    messages.add({'role': 'user', 'content': message});

    try {
      final content = await _post(messages: messages, temperature: 0.7);
      final fullPrompt = messages.map((m) => m['content']).join('\n');
      await _trackUsage(fullPrompt, content);
      return content;
    } catch (e) {
      throw Exception('$providerLabel Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
    int count = 5,
    String difficulty = 'Orta',
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }

    final prompt = promptTemplate
      .replaceAll('{referenceText}', referenceText)
      .replaceAll('{count}', count.toString())
      .replaceAll('{difficulty}', difficulty);

    try {
      final content = await _post(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );
      await _trackUsage(prompt, content);
      final List<dynamic> decoded = jsonDecode(_cleanJson(content));
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('$providerLabel Quiz Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({
    required String referenceText,
    required String type,
    required String mistakes,
  }) async {
    final prompt = Prompts.adaptiveQuizPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{quizType}', type)
        .replaceAll('{previousMistakes}', mistakes);

    try {
      final content = await _post(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
      );
      await _trackUsage(prompt, content);
      final List<dynamic> decoded = jsonDecode(_cleanJson(content));
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('$providerLabel Adaptive Quiz Hatası: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Concrete thin wrappers (config only – zero logic duplication)
// ─────────────────────────────────────────────────────────────────────────────

class GroqAiService extends BaseOpenAiCompatibleService {
  GroqAiService({required String apiKey})
      : super(
          apiKey: apiKey,
          baseUrl: 'https://api.groq.com/openai/v1',
          model: 'llama-3.3-70b-versatile',
          providerLabel: 'Groq',
        );
}

class OpenAiService extends BaseOpenAiCompatibleService {
  OpenAiService({required String apiKey})
      : super(
          apiKey: apiKey,
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o',
          providerLabel: 'OpenAI',
        );
}

class OllamaAiService extends BaseOpenAiCompatibleService {
  OllamaAiService({required String endpoint, required String model})
      : super(
          apiKey: '',
          baseUrl: '$endpoint/v1',
          model: model,
          providerLabel: 'Ollama ($model)',
        );
}

class CustomAiService extends BaseOpenAiCompatibleService {
  CustomAiService({
    required String apiKey,
    required String baseUrl,
    required String model,
  }) : super(
          apiKey: apiKey,
          baseUrl: baseUrl,
          model: model,
          providerLabel: 'Custom ($model)',
        );
}

// ─────────────────────────────────────────────────────────────────────────────
// Gemini – uses google_generative_ai SDK, NOT OpenAI-compatible
// ─────────────────────────────────────────────────────────────────────────────

class GeminiAiService implements AiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiAiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.1),
    );
  }

  Future<void> _trackUsage(String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage('Gemini', tokens);
  }

  @override
  Future<AiReport> analyzeExplanation({
    required String referenceText,
    required String transcript,
    required String targetAudience,
  }) async {
    final audienceLabel =
        Prompts.audienceLabels[targetAudience] ?? targetAudience;
    final prompt = Prompts.feynmanAnalysisPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{transcript}', transcript)
        .replaceAll('{audience}', audienceLabel);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final content = response.text ?? '{}';
      await _trackUsage(prompt, content);

      return AiReport.fromJson(jsonDecode(_cleanJson(content)));
    } catch (e) {
      throw Exception('Gemini API Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required String contextText,
    List<ChatMessage>? history,
  }) async {
    final systemPrompt =
        Prompts.chatPrompt.replaceAll('{notesContext}', contextText);

    final geminiModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
      systemInstruction: Content.system(systemPrompt),
    );

    final chatHistory = history
            ?.map((m) => Content(
                m.isUser == 1 ? 'user' : 'model', [TextPart(m.content)]))
            .toList() ??
        [];

    final chatSession = geminiModel.startChat(history: chatHistory);

    try {
      final response = await chatSession.sendMessage(Content.text(message));
      final responseText = response.text ?? '';

      final historyText = chatHistory
          .map(
              (e) => e.parts.map((p) => (p as TextPart).text).join('\n'))
          .join('\n');
      final fullPrompt = '$systemPrompt\n$historyText\n$message';
      await _trackUsage(fullPrompt, responseText);

      return responseText;
    } catch (e) {
      throw Exception('Gemini Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
    int count = 5,
    String difficulty = 'Orta',
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }
    final prompt = promptTemplate
      .replaceAll('{referenceText}', referenceText)
      .replaceAll('{count}', count.toString())
      .replaceAll('{difficulty}', difficulty);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final content = response.text ?? '[]';
      await _trackUsage(prompt, content);

      final List<dynamic> decoded = jsonDecode(_cleanJson(content));
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gemini Quiz Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({
    required String referenceText,
    required String type,
    required String mistakes,
  }) async {
    final prompt = Prompts.adaptiveQuizPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{quizType}', type)
        .replaceAll('{previousMistakes}', mistakes);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final content = response.text ?? '[]';
      await _trackUsage(prompt, content);

      final List<dynamic> decoded = jsonDecode(_cleanJson(content));
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gemini Adaptive Quiz Hatası: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local AI – uses flutter_gemma for strictly on-device inference
// ─────────────────────────────────────────────────────────────────────────────

class LocalAiService implements AiService {
  LocalAiService();

  Future<void> _trackUsage(String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage('Local Device', tokens);
  }

  @override
  Future<AiReport> analyzeExplanation({
    required String referenceText,
    required String transcript,
    required String targetAudience,
  }) async {
    final audienceLabel = Prompts.audienceLabels[targetAudience] ?? targetAudience;
    final prompt = Prompts.feynmanAnalysisPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{transcript}', transcript)
        .replaceAll('{audience}', audienceLabel);

    try {
      final model = await FlutterGemmaPlugin.instance.createModel(modelType: ModelType.gemmaIt, maxTokens: 1024);
      final session = await model.createSession(temperature: 0.2);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final content = await session.getResponse();
      
      await _trackUsage(prompt, content);
      
      await session.close();

      final startIndex = content.indexOf('{');
      final endIndex = content.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
        throw Exception("Analiz sonucu JSON formatında okunamadı.");
      }
      
      final cleanJson = content.substring(startIndex, endIndex + 1);
      return AiReport.fromJson(jsonDecode(cleanJson));
    } catch (e) {
      throw Exception('Local AI Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required String contextText,
    List<ChatMessage>? history,
  }) async {
    final systemPrompt = Prompts.chatPrompt.replaceAll('{notesContext}', contextText);
    
    try {
      final model = await FlutterGemmaPlugin.instance.createModel(modelType: ModelType.gemmaIt, maxTokens: 1024);
      final session = await model.createSession(temperature: 0.7);
      
      await session.addQueryChunk(Message(text: systemPrompt, isUser: true));
      await session.getResponse(); // Burn response
      
      if (history != null) {
        for (var msg in history) {
          await session.addQueryChunk(Message(text: msg.content, isUser: msg.isUser == 1));
          if (msg.isUser == 1) {
            await session.getResponse(); // Burn AI response filler
          }
        }
      }
      
      await session.addQueryChunk(Message(text: message, isUser: true));
      final responseText = await session.getResponse();
      
      final fullPrompt = '$systemPrompt\n$message';
      await _trackUsage(fullPrompt, responseText);
      
      await session.close();

      return responseText;
    } catch (e) {
      throw Exception('Local AI Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
    int count = 5,
    String difficulty = 'Orta',
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }
    final prompt = promptTemplate
      .replaceAll('{referenceText}', referenceText)
      .replaceAll('{count}', count.toString())
      .replaceAll('{difficulty}', difficulty);

    try {
      final model = await FlutterGemmaPlugin.instance.createModel(modelType: ModelType.gemmaIt, maxTokens: 1024);
      final session = await model.createSession(temperature: 0.2);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final content = await session.getResponse();
      await _trackUsage(prompt, content);
      await session.close();

      final startIndex = content.indexOf('[');
      final endIndex = content.lastIndexOf(']');
      if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
        throw Exception("Sınav sonucu JSON listesi formatında okunamadı.");
      }
      
      final cleanJson = content.substring(startIndex, endIndex + 1);
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Local Quiz Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({
    required String referenceText,
    required String type,
    required String mistakes,
  }) async {
    final prompt = Prompts.adaptiveQuizPrompt
        .replaceAll('{referenceText}', referenceText)
        .replaceAll('{quizType}', type)
        .replaceAll('{previousMistakes}', mistakes);

    try {
      final model = await FlutterGemmaPlugin.instance.createModel(modelType: ModelType.gemmaIt, maxTokens: 1024);
      final session = await model.createSession(temperature: 0.2);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final content = await session.getResponse();
      await _trackUsage(prompt, content);
      await session.close();

      final startIndex = content.indexOf('[');
      final endIndex = content.lastIndexOf(']');
      if (startIndex == -1 || endIndex == -1 || endIndex < startIndex) {
        throw Exception("Sınav sonucu JSON listesi formatında okunamadı.");
      }
      
      final cleanJson = content.substring(startIndex, endIndex + 1);
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Local Adaptive Quiz Hatası: $e');
    }
  }
}
