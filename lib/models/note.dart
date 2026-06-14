import 'dart:convert';

class Note {
  int? id;
  String title;
  String referenceText;
  String? transcript;
  double? score;
  String targetAudience;
  DateTime createdAt;

  Note({
    this.id,
    required this.title,
    required this.referenceText,
    this.transcript,
    this.score,
    required this.targetAudience,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reference_text': referenceText,
      'transcript': transcript,
      'score': score,
      'target_audience': targetAudience,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      referenceText: map['reference_text'],
      transcript: map['transcript'],
      score: map['score'],
      targetAudience: map['target_audience'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<NoteReference>? noteReferences;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.noteReferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'note_references': noteReferences != null
          ? jsonEncode(noteReferences!.map((x) => x.toMap()).toList())
          : null,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      content: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      noteReferences: map['note_references'] != null
          ? List<NoteReference>.from(jsonDecode(map['note_references'])
              .map((x) => NoteReference.fromMap(x)))
          : null,
    );
  }
}

class NoteReference {
  final int noteId;
  final String noteTitle;

  NoteReference({
    required this.noteId,
    required this.noteTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteTitle': noteTitle,
    };
  }

  factory NoteReference.fromMap(Map<String, dynamic> map) {
    return NoteReference(
      noteId: map['noteId'],
      noteTitle: map['noteTitle'],
    );
  }
}
