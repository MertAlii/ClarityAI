import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clarity_ai/core/services/database_service.dart';
import 'package:clarity_ai/models/v2_models.dart';

// Providers for fetching data
final foldersProvider = FutureProvider<List<Folder>>((ref) async {
  return await DatabaseService.instance.getAllFolders();
});

final notesProvider = FutureProvider.family<List<Note>, int?>((ref, folderId) async {
  return await DatabaseService.instance.getAllNotes(folderId: folderId);
});

final noteMaterialsProvider = FutureProvider.family<List<NoteMaterial>, int>((ref, noteId) async {
  return await DatabaseService.instance.getMaterialsForNote(noteId);
});

final aiReportsProvider = FutureProvider.family<List<AiReportData>, int>((ref, noteId) async {
  return await DatabaseService.instance.getReportsForNote(noteId);
});

final quizzesProvider = FutureProvider.family<List<QuizData>, int>((ref, noteId) async {
  return await DatabaseService.instance.getQuizzesForNote(noteId);
});

final chatSessionsProvider = FutureProvider<List<ChatSession>>((ref) async {
  return await DatabaseService.instance.getAllChatSessions();
});

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  return await DatabaseService.instance.getAllEvents();
});

// Settings & Stats
final tokenUsageProvider = FutureProvider.family<TokenUsage?, String>((ref, providerName) async {
  return await DatabaseService.instance.getTokenUsage(providerName);
});
