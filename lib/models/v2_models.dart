import 'dart:convert';

class Folder {
  int? id;
  String name;
  String? colorHex;
  DateTime createdAt;

  Folder({this.id, required this.name, this.colorHex, required this.createdAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'colorHex': colorHex,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Folder.fromMap(Map<String, dynamic> map) => Folder(
    id: map['id'],
    name: map['name'],
    colorHex: map['colorHex'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class Note {
  int? id;
  int? folderId;
  String title;
  String targetAudience;
  double? score;
  int isStarred;
  int priority;
  DateTime createdAt;

  Note({
    this.id,
    this.folderId,
    required this.title,
    required this.targetAudience,
    this.score,
    this.isStarred = 0,
    this.priority = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'folderId': folderId,
    'title': title,
    'targetAudience': targetAudience,
    'score': score,
    'isStarred': isStarred,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    folderId: map['folderId'],
    title: map['title'],
    targetAudience: map['targetAudience'],
    score: map['score'],
    isStarred: map['isStarred'] ?? 0,
    priority: map['priority'] ?? 0,
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class NoteMaterial {
  int? id;
  int noteId;
  String type; // 'text', 'pdf'
  String title;
  String content;
  DateTime createdAt;

  NoteMaterial({
    this.id,
    required this.noteId,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'noteId': noteId,
    'type': type,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NoteMaterial.fromMap(Map<String, dynamic> map) => NoteMaterial(
    id: map['id'],
    noteId: map['noteId'],
    type: map['type'],
    title: map['title'],
    content: map['content'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class AiReportData {
  int? id;
  int noteId;
  String type; // 'analysis', 'summary'
  String contentJson;
  double? score;
  DateTime createdAt;

  AiReportData({
    this.id,
    required this.noteId,
    required this.type,
    required this.contentJson,
    this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'noteId': noteId,
    'type': type,
    'contentJson': contentJson,
    'score': score,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AiReportData.fromMap(Map<String, dynamic> map) => AiReportData(
    id: map['id'],
    noteId: map['noteId'],
    type: map['type'],
    contentJson: map['contentJson'],
    score: map['score'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class QuizData {
  int? id;
  int noteId;
  String type; // 'test', 'classic', 'flashcard'
  String contentJson; // JSON string of questions/flashcards
  double? score; // If solved, user's score
  DateTime createdAt;

  QuizData({
    this.id,
    required this.noteId,
    required this.type,
    required this.contentJson,
    this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'noteId': noteId,
    'type': type,
    'contentJson': contentJson,
    'score': score,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuizData.fromMap(Map<String, dynamic> map) => QuizData(
    id: map['id'],
    noteId: map['noteId'],
    type: map['type'],
    contentJson: map['contentJson'],
    score: map['score'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class ChatSession {
  String id; // UUID
  String title;
  DateTime createdAt;

  ChatSession({required this.id, required this.title, required this.createdAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatSession.fromMap(Map<String, dynamic> map) => ChatSession(
    id: map['id'],
    title: map['title'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class ChatMessage {
  String id;
  String sessionId;
  int? noteId; // If null, global chat message
  String content;
  int isUser;
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sessionId,
    this.noteId,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sessionId': sessionId,
    'noteId': noteId,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'],
    sessionId: map['sessionId'],
    noteId: map['noteId'],
    content: map['content'],
    isUser: map['isUser'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}

class Event {
  int? id;
  String title;
  String dateStr; // YYYY-MM-DD
  String type; // 'exam', 'study'
  String? colorHex;

  Event({
    this.id,
    required this.title,
    required this.dateStr,
    required this.type,
    this.colorHex,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'dateStr': dateStr,
    'type': type,
    'colorHex': colorHex,
  };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
    id: map['id'],
    title: map['title'],
    dateStr: map['dateStr'],
    type: map['type'],
    colorHex: map['colorHex'],
  );
}

class TokenUsage {
  int? id;
  String provider;
  int tokensUsed;
  int requestsCount;
  int quotaLimit;

  TokenUsage({
    this.id,
    required this.provider,
    required this.tokensUsed,
    required this.requestsCount,
    required this.quotaLimit,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'provider': provider,
    'tokensUsed': tokensUsed,
    'requestsCount': requestsCount,
    'quotaLimit': quotaLimit,
  };

  factory TokenUsage.fromMap(Map<String, dynamic> map) => TokenUsage(
    id: map['id'],
    provider: map['provider'],
    tokensUsed: map['tokensUsed'],
    requestsCount: map['requestsCount'],
    quotaLimit: map['quotaLimit'],
  );
}

class UserProfile {
  String name;
  String aiProvider;
  bool onboardingCompleted;
  bool setupCompleted;
  String themeMode;

  UserProfile({
    required this.name,
    required this.aiProvider,
    this.onboardingCompleted = false,
    this.setupCompleted = false,
    this.themeMode = 'system',
  });
  
  Map<String, dynamic> toMap() => {
    'name': name,
    'aiProvider': aiProvider,
    'onboardingCompleted': onboardingCompleted,
    'setupCompleted': setupCompleted,
    'themeMode': themeMode,
  };
  
  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    name: map['name'] ?? '',
    aiProvider: map['aiProvider'] ?? 'groq',
    onboardingCompleted: map['onboardingCompleted'] ?? false,
    setupCompleted: map['setupCompleted'] ?? false,
    themeMode: map['themeMode'] ?? 'system',
  );
}

class AiReport {
  double score;
  List<dynamic> gaps;
  List<dynamic> jargon;
  List<dynamic> analogies;

  AiReport({
    required this.score,
    required this.gaps,
    required this.jargon,
    required this.analogies,
  });

  factory AiReport.fromJson(Map<String, dynamic> json) => AiReport(
    score: (json['score'] ?? 0).toDouble(),
    gaps: json['gaps'] ?? [],
    jargon: json['jargon'] ?? [],
    analogies: json['analogies'] ?? [],
  );
}
