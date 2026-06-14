import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:clarity_ai/models/note.dart';
import 'package:clarity_ai/models/ai_report.dart';
import 'package:clarity_ai/core/constants/prompts.dart';

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
}

class GroqAiService implements AiService {
  final String apiKey;
  final Dio _dio = Dio();

  GroqAiService({required this.apiKey}) {
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
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
      // Clean potential markdown blocks
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

      return response.data['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Groq Chat Hatası: $e');
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

      return response.data['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('OpenAI Chat Hatası: $e');
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
      return response.text ?? '';
    } catch (e) {
      throw Exception('Gemini Chat Hatası: $e');
    }
  }
}
