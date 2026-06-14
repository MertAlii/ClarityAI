import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:clarity_ai/models/v2_models.dart';

import 'package:clarity_ai/core/constants/prompts.dart';
import 'package:clarity_ai/core/services/database_service.dart';

abstract class AiService {
  Future<AiReport> analyzeExplanation({
    required String referenceText,
    required String transcript,
    required String targetAudience,
  });

  Future<String> chat({
    required String message,
    required List<Note> userNotes,
    List<ChatMessage>? history,
  });

  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
  });

  Future<List<Map<String, dynamic>>> generateAdaptiveQuiz({
    required String referenceText,
    required String type,
    required String mistakes,
  });
}

class GroqAiService implements AiService {
  final String apiKey;
  final Dio _dio = Dio();

  GroqAiService({required this.apiKey}) {
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<void> _trackUsage(String provider, String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage(provider, tokens, );
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
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('Groq', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      return AiReport.fromJson(jsonDecode(cleanJson));
    } catch (e) {
      throw Exception('Groq API Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required List<Note> userNotes,
    List<ChatMessage>? history,
  }) async {
    final notesContext = userNotes.map((n) => "Not #${n.id}: ${n.title}\n${n.referenceText.substring(0, n.referenceText.length > 500 ? 500 : n.referenceText.length)}").join("\n\n");
    final systemPrompt = Prompts.chatPrompt.replaceAll('{notesContext}', notesContext);

    final messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    if (history != null) {
      for (var msg in history) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    messages.add({'role': 'user', 'content': message});

    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final fullPrompt = messages.map((m) => m['content']).join('\n');
      await _trackUsage('Groq', fullPrompt, content);
      
      return content;
    } catch (e) {
      throw Exception('Groq Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }

    final prompt = promptTemplate.replaceAll('{referenceText}', referenceText);

    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('Groq', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Groq Quiz Hatası: $e');
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
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('Groq', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Groq Adaptive Quiz Hatası: $e');
    }
  }
}

class OpenAiService implements AiService {
  final String apiKey;
  final Dio _dio = Dio();

  OpenAiService({required this.apiKey}) {
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<void> _trackUsage(String provider, String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage(provider, tokens, );
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
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4o',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('OpenAI', prompt, content);
      
      return AiReport.fromJson(jsonDecode(content));
    } catch (e) {
      throw Exception('OpenAI API Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required List<Note> userNotes,
    List<ChatMessage>? history,
  }) async {
    final notesContext = userNotes.map((n) => "Not #${n.id}: ${n.title}\n${n.referenceText.substring(0, n.referenceText.length > 500 ? 500 : n.referenceText.length)}").join("\n\n");
    final systemPrompt = Prompts.chatPrompt.replaceAll('{notesContext}', notesContext);

    final messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    if (history != null) {
      for (var msg in history) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    messages.add({'role': 'user', 'content': message});

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': messages,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      final fullPrompt = messages.map((m) => m['content']).join('\n');
      await _trackUsage('OpenAI', fullPrompt, content);
      
      return content;
    } catch (e) {
      throw Exception('OpenAI Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }

    final prompt = promptTemplate.replaceAll('{referenceText}', referenceText);

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('OpenAI', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('OpenAI Quiz Hatası: $e');
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
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      await _trackUsage('OpenAI', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('OpenAI Adaptive Quiz Hatası: $e');
    }
  }
}

class GeminiAiService implements AiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiAiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.1),
    );
  }

  Future<void> _trackUsage(String provider, String prompt, String response) async {
    final tokens = (prompt.length + response.length) ~/ 4;
    await DatabaseService.instance.incrementTokenUsage(provider, tokens, );
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
      final response = await _model.generateContent([Content.text(prompt)]);
      final content = response.text ?? '{}';
      await _trackUsage('Gemini', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      return AiReport.fromJson(jsonDecode(cleanJson));
    } catch (e) {
      throw Exception('Gemini API Hatası: $e');
    }
  }

  @override
  Future<String> chat({
    required String message,
    required List<Note> userNotes,
    List<ChatMessage>? history,
  }) async {
    final notesContext = userNotes.map((n) => "Not #${n.id}: ${n.title}\n${n.referenceText.substring(0, n.referenceText.length > 500 ? 500 : n.referenceText.length)}").join("\n\n");
    final systemPrompt = Prompts.chatPrompt.replaceAll('{notesContext}', notesContext);

    final geminiModel = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
      systemInstruction: Content.system(systemPrompt),
    );

    final chatHistory = history?.map((m) {
      return Content(m.isUser ? 'user' : 'model', [TextPart(m.content)]);
    }).toList() ?? [];

    final chatSession = geminiModel.startChat(history: chatHistory);

    try {
      final response = await chatSession.sendMessage(Content.text(message));
      final responseText = response.text ?? '';
      
      final historyText = chatHistory.map((e) => e.parts.map((p) => (p as TextPart).text).join('\n')).join('\n');
      final fullPrompt = '$systemPrompt\n$historyText\n$message';
      await _trackUsage('Gemini', fullPrompt, responseText);
      
      return responseText;
    } catch (e) {
      throw Exception('Gemini Chat Hatası: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateQuiz({
    required String referenceText,
    required String type,
  }) async {
    String promptTemplate;
    if (type == 'test') {
      promptTemplate = Prompts.testPrompt;
    } else if (type == 'classic') {
      promptTemplate = Prompts.classicPrompt;
    } else {
      promptTemplate = Prompts.flashcardPrompt;
    }

    final prompt = promptTemplate.replaceAll('{referenceText}', referenceText);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final content = response.text ?? '[]';
      await _trackUsage('Gemini', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
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
      await _trackUsage('Gemini', prompt, content);
      
      final cleanJson = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gemini Adaptive Quiz Hatası: $e');
    }
  }
}
